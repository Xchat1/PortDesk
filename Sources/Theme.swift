import SwiftUI

struct Theme {
    static let primary = Color(red: 10.0 / 255.0, green: 132.0 / 255.0, blue: 1.0)
    static let primaryHover = Color(red: 0.0, green: 113.0 / 255.0, blue: 227.0 / 255.0)
    static let background = Color(red: 0.0, green: 0.0, blue: 0.0)
    static let surface = Color(red: 28.0 / 255.0, green: 28.0 / 255.0, blue: 30.0 / 255.0)
    static let surfaceVariant = Color(red: 44.0 / 255.0, green: 44.0 / 255.0, blue: 46.0 / 255.0)
    static let border = Color(red: 56.0 / 255.0, green: 56.0 / 255.0, blue: 58.0 / 255.0)
    static let cardBackground = surface

    // Status colors
    static let safeColor = Color(red: 48.0 / 255.0, green: 209.0 / 255.0, blue: 88.0 / 255.0)
    static let warningColor = Color(red: 1.0, green: 159.0 / 255.0, blue: 10.0 / 255.0)
    static let dangerColor = Color(red: 1.0, green: 69.0 / 255.0, blue: 58.0 / 255.0)
    static let neutralColor = Color.secondary

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
