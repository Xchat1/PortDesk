import SwiftUI

/// A complete set of theme colors for a single appearance (light or dark).
struct ThemePalette {
    let primary: Color
    let primaryHover: Color
    let background: Color
    let surface: Color
    let surfaceVariant: Color
    let border: Color
    let safeColor: Color
    let warningColor: Color
    let dangerColor: Color
    let neutralColor: Color

    var cardBackground: Color { surface }

    /// Dark palette — matches the PortDeck design system.
    static let dark = ThemePalette(
        primary: Color(red: 10.0 / 255.0, green: 132.0 / 255.0, blue: 1.0),
        primaryHover: Color(red: 0.0, green: 113.0 / 255.0, blue: 227.0 / 255.0),
        background: Color(red: 0.0, green: 0.0, blue: 0.0),
        surface: Color(red: 28.0 / 255.0, green: 28.0 / 255.0, blue: 30.0 / 255.0),
        surfaceVariant: Color(red: 44.0 / 255.0, green: 44.0 / 255.0, blue: 46.0 / 255.0),
        border: Color(red: 56.0 / 255.0, green: 56.0 / 255.0, blue: 58.0 / 255.0),
        safeColor: Color(red: 48.0 / 255.0, green: 209.0 / 255.0, blue: 88.0 / 255.0),
        warningColor: Color(red: 1.0, green: 159.0 / 255.0, blue: 10.0 / 255.0),
        dangerColor: Color(red: 1.0, green: 69.0 / 255.0, blue: 58.0 / 255.0),
        neutralColor: Color.secondary
    )

    /// Light palette — same semantic roles, tuned for contrast on white.
    static let light = ThemePalette(
        primary: Color(red: 10.0 / 255.0, green: 132.0 / 255.0, blue: 1.0),
        primaryHover: Color(red: 0.0, green: 113.0 / 255.0, blue: 227.0 / 255.0),
        background: Color(red: 245.0 / 255.0, green: 245.0 / 255.0, blue: 247.0 / 255.0),
        surface: Color(red: 255.0 / 255.0, green: 255.0 / 255.0, blue: 255.0 / 255.0),
        surfaceVariant: Color(red: 232.0 / 255.0, green: 232.0 / 255.0, blue: 237.0 / 255.0),
        border: Color(red: 210.0 / 255.0, green: 210.0 / 255.0, blue: 215.0 / 255.0),
        safeColor: Color(red: 30.0 / 255.0, green: 122.0 / 255.0, blue: 51.0 / 255.0),
        warningColor: Color(red: 199.0 / 255.0, green: 84.0 / 255.0, blue: 0.0 / 255.0),
        dangerColor: Color(red: 196.0 / 255.0, green: 40.0 / 255.0, blue: 27.0 / 255.0),
        neutralColor: Color.secondary
    )
}

struct Theme {
    /// The active palette, chosen from the resolved appearance.
    private static var palette: ThemePalette {
        AppearanceManager.shared.isDark ? .dark : .light
    }

    static var primary: Color { palette.primary }
    static var primaryHover: Color { palette.primaryHover }
    static var background: Color { palette.background }
    static var surface: Color { palette.surface }
    static var surfaceVariant: Color { palette.surfaceVariant }
    static var border: Color { palette.border }
    static var cardBackground: Color { palette.cardBackground }

    // Status colors
    static var safeColor: Color { palette.safeColor }
    static var warningColor: Color { palette.warningColor }
    static var dangerColor: Color { palette.dangerColor }
    static var neutralColor: Color { palette.neutralColor }

    static let cardRadius: CGFloat = 14
    static let controlRadius: CGFloat = 8
    static let badgeRadius: CGFloat = 6
    
    // Font modifiers
    static func headlineFont() -> Font {
        return .system(size: 22, weight: .bold, design: .default)
    }

    static func titleFont() -> Font {
        return headlineFont()
    }

    static func cardTitleFont() -> Font {
        return .system(size: 17, weight: .semibold, design: .default)
    }
    
    static func sectionFont() -> Font {
        return .system(size: 15, weight: .semibold, design: .default)
    }
    
    static func bodyFont() -> Font {
        return .system(size: 13, weight: .regular, design: .default)
    }

    static func captionFont() -> Font {
        return .system(size: 11, weight: .regular, design: .default)
    }
    
    static func monoFont() -> Font {
        return .system(size: 12, weight: .regular, design: .monospaced)
    }
}

struct PortDeckCardModifier: ViewModifier {
    var cornerRadius: CGFloat = Theme.cardRadius
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.border.opacity(0.55), lineWidth: 1)
            )
    }
}

extension View {
    func portDeckCard(cornerRadius: CGFloat = Theme.cardRadius, padding: CGFloat = 16) -> some View {
        modifier(PortDeckCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 32)
            .background(configuration.isPressed ? Theme.primaryHover : Theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    var foregroundColor: Color = .primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 32)
            .background(Theme.surfaceVariant.opacity(configuration.isPressed ? 0.85 : 0.55))
            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                    .stroke(Theme.border.opacity(0.6), lineWidth: 1)
            )
    }
}

struct DestructiveActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(Theme.dangerColor.opacity(configuration.isPressed ? 0.82 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
    }
}
