import Foundation

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var activePortCount = 0
    @Published var exposedCount = 0
    @Published var lastScanDate: Date?
    @Published var isScanning = false
}

enum AppInfo {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

/// Supported auto-refresh intervals (seconds). `0` means manual only.
enum RefreshInterval {
    static let options: [Double] = [
        0,
        1, 3, 5, 10, 30,
        60,
        5 * 60,
        15 * 60,
        30 * 60,
        60 * 60,
        3 * 3600,
        5 * 3600,
        10 * 3600,
        12 * 3600
    ]

    static func label(seconds: Double, chinese: Bool) -> String {
        if seconds <= 0 {
            return chinese ? "仅手动" : "Manual only"
        }
        if seconds < 60 {
            let n = Int(seconds)
            if chinese { return "\(n) 秒" }
            return n == 1 ? "1 Second" : "\(n) Seconds"
        }
        if seconds < 3600 {
            let n = Int(seconds / 60)
            if chinese { return "\(n) 分钟" }
            return n == 1 ? "1 Minute" : "\(n) Minutes"
        }
        let n = Int(seconds / 3600)
        if chinese { return "\(n) 小时" }
        return n == 1 ? "1 Hour" : "\(n) Hours"
    }

    /// Timer energy tolerance; longer intervals tolerate more drift.
    static func tolerance(for seconds: Double) -> TimeInterval {
        guard seconds > 0 else { return 0 }
        return min(seconds * 0.1, 300)
    }
}

