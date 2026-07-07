import SwiftUI

struct ActionLogView: View {
    let logs: [ActionLogItem]
    let onRefresh: () -> Void

    @ObservedObject private var loc = Localization.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            if logs.isEmpty {
                EmptyStateView(
                    icon: "doc.text.magnifyingglass",
                    title: loc.t("logs_empty_title"),
                    message: loc.t("logs_empty_desc")
                )
            } else {
                List(logs) { log in
                    ActionLogRow(log: log)
                        .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Theme.background.opacity(0.28))
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(loc.t("logs_title"))
                    .font(Theme.titleFont())

                Text(loc.currentLanguage == .chinese ? "敏感操作会保留在这里，方便回看。" : "Sensitive actions stay here for review.")
                    .font(Theme.bodyFont())
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onRefresh) {
                Label(loc.t("logs_btn_refresh"), systemImage: "arrow.clockwise")
            }
            .buttonStyle(SecondaryActionButtonStyle())
        }
        .padding(24)
    }
}

struct ActionLogRow: View {
    let log: ActionLogItem

    @ObservedObject private var loc = Localization.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                BadgeView(text: log.actionType, color: badgeColor(for: log.actionType), icon: badgeIcon(for: log.actionType))

                Text(log.target)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Text(log.formattedTime)
                    .font(Theme.monoFont())
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            MonoBlock(text: log.details, lineLimit: 2)

            HStack(spacing: 6) {
                Text(loc.t("logs_prop_status"))
                    .font(Theme.captionFont())
                    .foregroundColor(.secondary)

                Text(log.status)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(statusColor(for: log.status))

                Spacer()
            }
        }
        .portDeckCard(cornerRadius: Theme.controlRadius, padding: 14)
    }

    private func badgeColor(for type: String) -> Color {
        switch type {
        case "SIGTERM": return Theme.primary
        case "SIGKILL": return Theme.dangerColor
        case "Empty Trash": return Theme.warningColor
        default: return .secondary
        }
    }

    private func badgeIcon(for type: String) -> String {
        switch type {
        case "SIGTERM": return "stop.circle"
        case "SIGKILL": return "xmark.octagon"
        case "Empty Trash": return "trash"
        default: return "doc.text"
        }
    }

    private func statusColor(for status: String) -> Color {
        if status == "Success" { return Theme.safeColor }
        if status.contains("Needs") { return Theme.warningColor }
        return Theme.dangerColor
    }
}
