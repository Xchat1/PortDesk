import Foundation
import Security
import Darwin

struct PortServiceItem: Identifiable, Hashable {
    var id: String { "\(pid)" }
    let pid: Int32
    var ppid: Int32
    var processName: String
    let userName: String
    var ports: [Int]
    var host: String
    let protocolName: String // TCP / UDP
    var isLocalOnly: Bool
    var path: String?
    var cwd: String?
    var commandLine: String?
    var parentProcessName: String?
    var framework: String
    var isAppleSigned: Bool
    var isSystemProcess: Bool
    
    // UI computed fields
    var riskLevel: String {
        if !isLocalOnly {
            return "warning"
        }
        if isSystemProcess || isAppleSigned {
            return "safe"
        }
        return "neutral"
    }
}

final class PortService: @unchecked Sendable {
    static let shared = PortService()
    
    private var signatureCache: [String: Bool] = [:]
    private let cacheLock = NSLock()
    private var isScanInProgress = false
    private var lastScanResults: [PortServiceItem] = []
    
    // Check if the process path is signed by Apple
    private func checkAppleSignature(at path: String) -> Bool {
        cacheLock.lock()
        if let cached = signatureCache[path] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()
        
        let url = URL(fileURLWithPath: path)
        var staticCode: SecStaticCode?
        guard SecStaticCodeCreateWithPath(url as CFURL, [], &staticCode) == errSecSuccess,
              let code = staticCode else {
            return false
        }
        
        let requirementString = "anchor apple" as CFString
        var requirement: SecRequirement?
        guard SecRequirementCreateWithString(requirementString, [], &requirement) == errSecSuccess,
              let req = requirement else {
            return false
        }
        
        let status = SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: 0), req)
        let isSigned = status == errSecSuccess
        
        cacheLock.lock()
        signatureCache[path] = isSigned
        // Simple cache cleanup to prevent unbounded growth if many unique paths are seen
        if signatureCache.count > 1000 {
            signatureCache.removeAll()
        }
        cacheLock.unlock()
        
        return isSigned
    }
    
    // Get executable path using native proc_pidpath
    private func getExecutablePath(for pid: Int32) -> String? {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(PATH_MAX))
        defer { buffer.deallocate() }
        let result = proc_pidpath(pid, buffer, UInt32(PATH_MAX))
        if result > 0 {
            return String(cString: buffer)
        }
        return nil
    }
    
    // Execute a shell command and return its output
    private func runCommand(executable: String, arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe() // Silence stderr
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    private func isSystemExecutablePath(_ path: String) -> Bool {
        path.hasPrefix("/System/") ||
        path.hasPrefix("/usr/sbin/") ||
        path.hasPrefix("/usr/libexec/") ||
        path.hasPrefix("/sbin/")
    }

    // Scan all active TCP listening ports and gather their metadata
    func scanActivePorts(completion: @escaping ([PortServiceItem]) -> Void) {
        cacheLock.lock()
        if isScanInProgress {
            let cached = lastScanResults
            cacheLock.unlock()
            DispatchQueue.main.async { completion(cached) }
            return
        }
        isScanInProgress = true
        cacheLock.unlock()

        // Run scanner on utility queue to keep UI buttery smooth and save power
        DispatchQueue.global(qos: .utility).async {
            defer {
                self.cacheLock.lock()
                self.isScanInProgress = false
                self.cacheLock.unlock()
            }

            var items: [PortServiceItem] = []
            
            // Step 1: Run lsof -nP -iTCP -sTCP:LISTEN -F
            guard let lsofOutput = self.runCommand(executable: "/usr/sbin/lsof", arguments: ["-nP", "-iTCP", "-sTCP:LISTEN", "-F"]) else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            // Parse lsof output
            var currentPid: Int32?
            var currentCommand: String?
            var currentUser: String?
            
            // Temporary struct storage grouped by PID to batch-query Cwd and Args
            var pidItemsMap: [Int32: [PortServiceItem]] = [:]
            
            let lines = lsofOutput.components(separatedBy: .newlines)
            for line in lines {
                if line.isEmpty { continue }
                let prefix = line.prefix(1)
                let value = String(line.dropFirst())
                
                switch prefix {
                case "p":
                    if let pidVal = Int32(value) {
                        currentPid = pidVal
                    }
                case "c":
                    currentCommand = value
                case "L":
                    currentUser = value
                case "f":
                    // A new file descriptor means we should have collected PID/Command/User
                    // Next lines will contain the name/address details
                    break
                case "n":
                    // Parse address and port from name e.g. "127.0.0.1:10007" or "*:7000" or "[::1]:5432"
                    guard let pid = currentPid else { continue }
                    let name = value
                    
                    let parts = name.components(separatedBy: ":")
                    guard parts.count >= 2 else { continue }
                    
                    let portString = parts.last!
                    let host = parts.dropLast().joined(separator: ":")
                    
                    guard let port = Int(portString) else { continue }
                    
                    let isLocal = host.contains("127.0.0.1") || host.contains("localhost") || host.contains("::1") || host.contains("[::1]")
                    
                    let item = PortServiceItem(
                        pid: pid,
                        ppid: 0, // Filled in batch
                        processName: currentCommand ?? "Unknown",
                        userName: currentUser ?? "Unknown",
                        ports: [port],
                        host: host,
                        protocolName: "TCP",
                        isLocalOnly: isLocal,
                        path: nil,
                        cwd: nil,
                        commandLine: nil,
                        parentProcessName: nil,
                        framework: "Unknown",
                        isAppleSigned: false,
                        isSystemProcess: false
                    )
                    
                    if pidItemsMap[pid] == nil {
                        pidItemsMap[pid] = []
                    }
                    pidItemsMap[pid]?.append(item)
                    
                default:
                    break
                }
            }
            
            let activePids = Array(pidItemsMap.keys)
            if activePids.isEmpty {
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            // Helper to chunk array
            let chunkSize = 50
            func chunkedPids(_ pids: [Int32]) -> [[Int32]] {
                return stride(from: 0, to: pids.count, by: chunkSize).map {
                    Array(pids[$0 ..< Swift.min($0 + chunkSize, pids.count)])
                }
            }
            
            // Step 2: Batch query PPID and Command Arguments via ps
            var ppidMap: [Int32: Int32] = [:]
            var commandLineMap: [Int32: String] = [:]
            
            for chunk in chunkedPids(activePids) {
                let pidListString = chunk.map { String($0) }.joined(separator: ",")
                if let psOutput = self.runCommand(executable: "/bin/ps", arguments: ["-p", pidListString, "-o", "pid=,ppid=,args="]) {
                    let psLines = psOutput.components(separatedBy: .newlines)
                    for line in psLines {
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty { continue }
                        
                        // Format: "PID PPID ARGS..."
                        let components = trimmed.components(separatedBy: .whitespaces)
                        let filtered = components.filter { !$0.isEmpty }
                        if filtered.count >= 3 {
                            if let pidVal = Int32(filtered[0]),
                               let ppidVal = Int32(filtered[1]) {
                                ppidMap[pidVal] = ppidVal
                                let args = filtered.dropFirst(2).joined(separator: " ")
                                commandLineMap[pidVal] = args
                            }
                        }
                    }
                }
            }
            
            // Step 3: Batch query Cwd via lsof
            var cwdMap: [Int32: String] = [:]
            for chunk in chunkedPids(activePids) {
                let pidListString = chunk.map { String($0) }.joined(separator: ",")
                if let cwdOutput = self.runCommand(executable: "/usr/sbin/lsof", arguments: ["-p", pidListString, "-a", "-d", "cwd", "-Fn"]) {
                    let cwdLines = cwdOutput.components(separatedBy: .newlines)
                    var currentCwdPid: Int32?
                    for line in cwdLines {
                        if line.isEmpty { continue }
                        let prefix = line.prefix(1)
                        let value = String(line.dropFirst())
                        
                        if prefix == "p" {
                            currentCwdPid = Int32(value)
                        } else if prefix == "n", let pid = currentCwdPid {
                            cwdMap[pid] = value
                        }
                    }
                }
            }
            
            // Step 4: Resolve Parent process names in batch
            let parentPids = Array(Set(ppidMap.values))
            var parentNamesMap: [Int32: String] = [:]
            if !parentPids.isEmpty {
                for chunk in chunkedPids(parentPids) {
                    let parentPidsList = chunk.map { String($0) }.joined(separator: ",")
                    if let parentPsOutput = self.runCommand(executable: "/bin/ps", arguments: ["-p", parentPidsList, "-o", "pid=,comm="]) {
                        let pLines = parentPsOutput.components(separatedBy: .newlines)
                        for line in pLines {
                            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                            if trimmed.isEmpty { continue }
                            let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                            if parts.count >= 2, let pidVal = Int32(parts[0]) {
                                let path = parts.dropFirst().joined(separator: " ")
                                let name = URL(fileURLWithPath: path).lastPathComponent
                                parentNamesMap[pidVal] = name
                            }
                        }
                    }
                }
            }
            
            // Step 5: Fill details, perform signature checking & framework identification
            for pid in activePids {
                guard let processItems = pidItemsMap[pid], !processItems.isEmpty else { continue }
                
                let ppid = ppidMap[pid] ?? 0
                let commandLine = commandLineMap[pid]
                let cwd = cwdMap[pid]
                let path = self.getExecutablePath(for: pid)
                let parentName = parentNamesMap[ppid]
                
                var isApple = false
                var isSystem = false
                var realProcessName = processItems[0].processName
                
                if let execPath = path {
                    isSystem = self.isSystemExecutablePath(execPath)
                    if isSystem {
                        isApple = true
                    } else {
                        isApple = self.checkAppleSignature(at: execPath)
                    }
                    realProcessName = URL(fileURLWithPath: execPath).lastPathComponent
                }
                
                var baseItem = processItems[0]
                
                // Merge multiple ports for the same PID
                var allPorts = Set<Int>()
                var isLocal = true
                var host = "127.0.0.1"
                
                for p in processItems {
                    allPorts.insert(p.ports[0])
                    if !p.isLocalOnly {
                        isLocal = false
                        host = p.host // Pick the exposed host e.g. * or 0.0.0.0
                    }
                }
                
                baseItem.ports = Array(allPorts).sorted()
                baseItem.isLocalOnly = isLocal
                baseItem.host = host
                baseItem.path = path
                baseItem.ppid = ppid
                baseItem.commandLine = commandLine
                baseItem.cwd = cwd
                baseItem.parentProcessName = parentName
                baseItem.isAppleSigned = isApple
                baseItem.isSystemProcess = isSystem
                baseItem.processName = realProcessName
                
                // Framework detection
                baseItem.framework = self.detectFramework(
                    processName: realProcessName,
                    commandLine: commandLine,
                    cwd: cwd,
                    port: baseItem.ports.first ?? 0
                )
                
                items.append(baseItem)
            }
            
            // Sort: warning/unexposed first, then by port number
            let sortedItems = items.sorted {
                if $0.riskLevel != $1.riskLevel {
                    // warning is riskier than neutral, safe
                    let score = { (risk: String) -> Int in
                        switch risk {
                        case "warning": return 2
                        case "neutral": return 1
                        default: return 0
                        }
                    }
                    return score($0.riskLevel) > score($1.riskLevel)
                }
                return ($0.ports.first ?? 0) < ($1.ports.first ?? 0)
            }
            
            self.cacheLock.lock()
            self.lastScanResults = sortedItems
            self.cacheLock.unlock()

            DispatchQueue.main.async {
                completion(sortedItems)
            }
        }
    }
    
    private var frameworkCache: [String: String] = [:]
    
    // Mult-factor framework identification
    private func detectFramework(processName: String, commandLine: String?, cwd: String?, port: Int) -> String {
        let pName = processName.lowercased()
        let cmd = commandLine?.lowercased() ?? ""
        
        // Cache key for disk-heavy node detection
        let cacheKey = "\(cwd ?? "")-\(cmd)"
        
        cacheLock.lock()
        let cached = frameworkCache[cacheKey]
        cacheLock.unlock()
        
        if let cached = cached {
            return cached
        }
        
        var detectedFramework = processName
        
        // 1. PostgreSQL
        if pName.contains("postgres") {
            detectedFramework = "PostgreSQL"
        }
        
        // 2. Ollama
        else if pName.contains("ollama") {
            detectedFramework = "Ollama"
        }
        
        // 3. Docker
        else if pName.contains("docker") || pName.contains("vpnkit") || pName.contains("com.docker") {
            detectedFramework = "Docker"
        }
        
        // 4. Node.js frameworks
        else if pName.contains("node") {
            if cmd.contains("next-server") || cmd.contains("next dev") {
                detectedFramework = "Next.js"
            } else if cmd.contains("vite") {
                detectedFramework = "Vite (React/Vue)"
            } else if cmd.contains("react-scripts") {
                detectedFramework = "React (CRA)"
            } else if cmd.contains("gatsby") {
                detectedFramework = "Gatsby"
            } else if cmd.contains("nuxt") {
                detectedFramework = "NuxtJS"
            } else if cmd.contains("nest") {
                detectedFramework = "NestJS"
            } else if let cwdPath = cwd {
                // Inspect CWD files if possible
                let fm = FileManager.default
                if fm.fileExists(atPath: URL(fileURLWithPath: cwdPath).appendingPathComponent("next.config.js").path) ||
                    fm.fileExists(atPath: URL(fileURLWithPath: cwdPath).appendingPathComponent("next.config.mjs").path) {
                    detectedFramework = "Next.js"
                } else if fm.fileExists(atPath: URL(fileURLWithPath: cwdPath).appendingPathComponent("vite.config.ts").path) ||
                    fm.fileExists(atPath: URL(fileURLWithPath: cwdPath).appendingPathComponent("vite.config.js").path) {
                    detectedFramework = "Vite"
                } else {
                    detectedFramework = "Node.js"
                }
            } else {
                detectedFramework = "Node.js"
            }
        }
        
        // 5. Python frameworks
        else if pName.contains("python") {
            if cmd.contains("uvicorn") || cmd.contains("fastapi") {
                detectedFramework = "FastAPI"
            } else if cmd.contains("manage.py runserver") {
                detectedFramework = "Django"
            } else if cmd.contains("flask") {
                detectedFramework = "Flask"
            } else {
                detectedFramework = "Python Server"
            }
        }
        
        // 6. Go
        else if cmd.contains("go run") || pName.hasPrefix("go") {
            detectedFramework = "Go App"
        }
        
        // 7. Java / Spring
        else if pName.contains("java") {
            if cmd.contains("spring-boot") || cmd.contains("-jar") {
                detectedFramework = "Spring Boot"
            } else {
                detectedFramework = "Java App"
            }
        }
        
        // 8. Redis
        else if pName.contains("redis") {
            detectedFramework = "Redis"
        }
        
        // Port-based fallback if still unknown
        else {
            switch port {
            case 3000: detectedFramework = "Next.js/Vite (Port 3000)"
            case 5432: detectedFramework = "PostgreSQL"
            case 6379: detectedFramework = "Redis"
            case 8000: detectedFramework = "FastAPI/Django (Port 8000)"
            case 8080: detectedFramework = "Java/Server (Port 8080)"
            case 11434: detectedFramework = "Ollama"
            default: break
            }
        }
        
        cacheLock.lock()
        frameworkCache[cacheKey] = detectedFramework
        if frameworkCache.count > 1000 {
            frameworkCache.removeAll()
        }
        cacheLock.unlock()
        
        return detectedFramework
    }
    
    // Shut down service gracefully
    func stopService(pid: Int32, force: Bool, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let signal = force ? "-9" : "-15" // SIGKILL / SIGTERM
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/kill")
            process.arguments = [signal, String(pid)]
            
            do {
                try process.run()
                process.waitUntilExit()
                let success = process.terminationStatus == 0
                
                // If it was SIGTERM, check if the process actually exited after 3 seconds
                if !force && success {
                    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 3.0) {
                        // Check if it still exists using POSIX kill
                        let exists = kill(pid, 0) == 0
                        DispatchQueue.main.async {
                            completion(!exists) // success if it no longer exists
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(success)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
}
