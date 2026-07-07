import Foundation

struct ActionLogItem: Identifiable, Codable, Equatable {
    let id: String
    let timestamp: Date
    let actionType: String // e.g. "SIGTERM", "SIGKILL", "Empty Trash"
    let target: String // e.g. "PID 440 (postgres) on Port 5432"
    let details: String // e.g. "Working dir: /opt/homebrew, Command: postgres -D ..."
    let status: String // e.g. "Success", "Failed", "Process Active (Needs Kill)"

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    init(timestamp: Date, actionType: String, target: String, details: String, status: String) {
        self.timestamp = timestamp
        self.actionType = actionType
        self.target = target
        self.details = details
        self.status = status
        self.id = "\(Int(timestamp.timeIntervalSince1970 * 1000))-\(target.hashValue)"
    }

    var formattedTime: String {
        Self.timeFormatter.string(from: timestamp)
    }
}

final class ActionLogService: @unchecked Sendable {
    static let shared = ActionLogService()

    private var logsDirectory: URL {
        let fm = FileManager.default
        let libraryLogs = fm.urls(for: .libraryDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Logs")
            .appendingPathComponent("PortDeck")
        try? fm.createDirectory(at: libraryLogs, withIntermediateDirectories: true, attributes: nil)
        return libraryLogs
    }

    private var logFileURL: URL {
        return logsDirectory.appendingPathComponent("actions.json")
    }

    // Write an action log entry
    func logAction(type: String, target: String, details: String, status: String) {
        let entry = ActionLogItem(
            timestamp: Date(),
            actionType: type,
            target: target,
            details: details,
            status: status
        )

        DispatchQueue.global(qos: .utility).async {
            var existingLogs = self.loadLogsSync()
            existingLogs.insert(entry, at: 0) // Prepend newest

            // Limit to last 100 entries to prevent files growing too large
            if existingLogs.count > 100 {
                existingLogs = Array(existingLogs.prefix(100))
            }

            if let data = try? JSONEncoder().encode(existingLogs) {
                try? data.write(to: self.logFileURL)
            }
        }
    }

    // Load logs synchronously
    private func loadLogsSync() -> [ActionLogItem] {
        guard let data = try? Data(contentsOf: logFileURL) else {
            return []
        }
        return (try? JSONDecoder().decode([ActionLogItem].self, from: data)) ?? []
    }

    // Load logs asynchronously
    func loadLogs(completion: @escaping ([ActionLogItem]) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let logs = self.loadLogsSync()
            DispatchQueue.main.async {
                completion(logs)
            }
        }
    }
}
