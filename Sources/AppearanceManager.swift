import SwiftUI
import AppKit

/// User-facing appearance preference for PortDeck.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
}

/// Tracks the user's appearance preference and the live system appearance,
/// then resolves the effective `ColorScheme` the app should render with.
///
/// - "system" follows the macOS light/dark setting (auto switching).
/// - "light"/"dark" force a fixed appearance (manual switching).
final class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()

    /// User preference, persisted to UserDefaults as a raw string.
    @Published var mode: AppearanceMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.modeKey) }
    }

    /// The live system appearance; updates when the OS theme changes.
    @Published private(set) var systemScheme: ColorScheme

    /// Effective color scheme to apply, or `nil` to follow the system.
    var resolvedColorScheme: ColorScheme? {
        switch mode {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    /// `true` when the resolved appearance is dark (used by `Theme` to pick a palette).
    var isDark: Bool {
        if let resolved = resolvedColorScheme { return resolved == .dark }
        return systemScheme == .dark
    }

    private static let modeKey = "appearance_mode"

    private init() {
        let raw = UserDefaults.standard.string(forKey: Self.modeKey)
        self.mode = AppearanceMode(rawValue: raw ?? "") ?? .system
        self.systemScheme = Self.currentSystemScheme()

        DistributedNotificationCenter.default.addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.systemScheme = Self.currentSystemScheme()
        }
    }

    private static func currentSystemScheme() -> ColorScheme {
        let isDark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        return isDark ? .dark : .light
    }
}
