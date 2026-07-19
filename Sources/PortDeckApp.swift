import SwiftUI
import AppKit

@main
struct PortDeckApp: App {
    @StateObject private var appState = AppState.shared
    @ObservedObject private var loc = Localization.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 960, minHeight: 620)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)

        MenuBarExtra {
            Button(action: openMainWindow) {
                Label(loc.t("menubar_open"), systemImage: "macwindow")
            }

            Divider()

            if appState.exposedCount > 0 {
                Text(String(format: loc.t("menubar_exposed"), appState.exposedCount))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(String(format: loc.t("menubar_active"), appState.activePortCount))
                .font(.caption)
                .foregroundColor(.secondary)

            if let lastScan = appState.lastScanDate {
                Text(String(format: loc.t("menubar_last_scan"), formattedScanTime(lastScan)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Divider()

            Button(action: refreshFromMenuBar) {
                Label(loc.t("menubar_refresh"), systemImage: "arrow.clockwise")
            }
            .disabled(appState.isScanning)

            Divider()

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Label(loc.t("menubar_quit"), systemImage: "power")
            }
        } label: {
            Image(systemName: appState.exposedCount > 0 ? "exclamationmark.triangle.fill" : "network")
        }
        .menuBarExtraStyle(.menu)
    }

    private func openMainWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first(where: { $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(nil)
        }
    }

    private func refreshFromMenuBar() {
        NotificationCenter.default.post(name: .portDeckRefreshRequested, object: nil)
    }

    private func formattedScanTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

extension Notification.Name {
    static let portDeckRefreshRequested = Notification.Name("portDeckRefreshRequested")
}
