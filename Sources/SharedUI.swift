import SwiftUI

enum FrameworkSymbol {
    static func name(for framework: String) -> String {
        switch framework {
        case "PostgreSQL": return "cylinder.split.1x2.fill"
        case "Ollama": return "brain.head.profile"
        case "Docker": return "square.stack.3d.up.fill"
        case "Next.js", "Vite (React/Vue)", "React (CRA)", "Node.js": return "atom"
        case "FastAPI", "Django", "Flask", "Python Server": return "terminal.fill"
        default: return "network"
        }
    }
}

struct BadgeView: View {
    let text: String
    let color: Color
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }

            Text(text)
                .font(.system(size: 10, weight: .bold))
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .clipShape(RoundedRectangle(cornerRadius: Theme.badgeRadius, style: .continuous))
    }
}

struct ServiceStatusBadge: View {
    let item: PortServiceItem

    @ObservedObject private var loc = Localization.shared

    var body: some View {
        if item.isSystemProcess || item.isAppleSigned {
            BadgeView(text: loc.t("badge_system"), color: .secondary, icon: "checkmark.seal.fill")
        } else if item.isLocalOnly {
            BadgeView(text: loc.t("badge_local"), color: Theme.safeColor, icon: "lock.fill")
        } else {
            BadgeView(text: loc.t("badge_exposed"), color: Theme.warningColor, icon: "wifi.exclamationmark")
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    var message: String? = nil

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .medium))
                .foregroundColor(.secondary)

            Text(title)
                .font(Theme.sectionFont())
                .foregroundColor(.secondary)

            if let message {
                Text(message)
                    .font(Theme.bodyFont())
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .frame(maxWidth: 360)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MonoBlock: View {
    let text: String
    var lineLimit: Int? = 2

    var body: some View {
        Text(text)
            .font(Theme.monoFont())
            .foregroundColor(.secondary)
            .lineLimit(lineLimit)
            .truncationMode(.middle)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surfaceVariant.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                    .stroke(Theme.border.opacity(0.45), lineWidth: 1)
            )
    }
}
