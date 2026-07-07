import Foundation
import AppKit

struct TrashInfo {
    let sizeBytes: Int64
    let fileCount: Int
    
    var formattedSize: String {
        if sizeBytes == 0 { return "0 B" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: sizeBytes)
    }
}

final class TrashService: @unchecked Sendable {
    static let shared = TrashService()
    
    private var lastScanDate: Date? = nil
    private var cachedInfo: TrashInfo = TrashInfo(sizeBytes: 0, fileCount: 0)
    private let cacheLock = NSLock()
    
    // Scan Trash size and file count in the background
    func scanTrashInfo(completion: @escaping (TrashInfo) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let trashURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
            
            // Optimization: Only scan if the .Trash folder's modification date has changed
            if let attrs = try? FileManager.default.attributesOfItem(atPath: trashURL.path),
               let modDate = attrs[.modificationDate] as? Date {
                self.cacheLock.lock()
                let lastDate = self.lastScanDate
                let cached = self.cachedInfo
                self.cacheLock.unlock()
                
                if let lastDate = lastDate, lastDate == modDate {
                    DispatchQueue.main.async {
                        completion(cached)
                    }
                    return
                }
                
                self.cacheLock.lock()
                self.lastScanDate = modDate
                self.cacheLock.unlock()
            }
            
            var totalSize: Int64 = 0
            var count = 0
            
            let fileManager = FileManager.default
            if let enumerator = fileManager.enumerator(at: trashURL, includingPropertiesForKeys: [.fileSizeKey], options: []) {
                for case let fileURL as URL in enumerator {
                    // Check if file size can be read
                    if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                       let fileSize = resourceValues.fileSize {
                        totalSize += Int64(fileSize)
                        count += 1
                    }
                }
            }
            
            let info = TrashInfo(sizeBytes: totalSize, fileCount: count)
            self.cacheLock.lock()
            self.cachedInfo = info
            self.cacheLock.unlock()
            
            DispatchQueue.main.async {
                completion(info)
            }
        }
    }
    
    // Open Trash in Finder
    func openTrashInFinder() {
        let trashURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
        NSWorkspace.shared.open(trashURL)
    }
    
    // Trigger Finder to empty the trash
    func emptyTrash(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let scriptSource = "tell application \"Finder\" to empty trash"
            guard let appleScript = NSAppleScript(source: scriptSource) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            
            let success = error == nil
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
}
