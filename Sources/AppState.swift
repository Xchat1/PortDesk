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
