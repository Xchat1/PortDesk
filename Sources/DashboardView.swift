import SwiftUI

struct DashboardView: View {
    let activeItems: [PortServiceItem]
    let exposedServicesCount: Int
    let trashInfo: TrashInfo
    let onNavigateToPorts: () -> Void
    let onEmptyTrash: () -> Void

    @ObservedObject private var loc = Localization.shared

    private let statColumns = [
        GridItem(.flexible(minimum: 180), spacing: 16),
        GridItem(.flexible(minimum: 180), spacing: 16),
        GridItem(.flexible(minimum: 180), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                LazyVGrid(columns: statColumns, spacing: 16) {
                    DashboardStatCard(
                        title: loc.t("db_stat_active"),
                        value: "\(activeItems.count)",
                        subtitle: loc.t("db_stat_listening"),
                        icon: "network",
                        valueColor: Theme.primary,
                        action: onNavigateToPorts
                    )

                    DashboardStatCard(
                        title: loc.t("db_stat_exposed"),
                        value: "\(exposedServicesCount)",
                        subtitle: loc.t("db_stat_exposed_sub"),
                        icon: exposedServicesCount > 0 ? "exclamationmark.triangle.fill" : "shield.checkmark.fill",
                        valueColor: exposedServicesCount > 0 ? Theme.warningColor : Theme.safeColor,
                        action: onNavigateToPorts
                    )

                    DashboardStatCard(
                        title: loc.t("db_stat_trash"),
                        value: trashInfo.formattedSize,
                        subtitle: String(format: loc.t("db_stat_trash_sub"), trashInfo.fileCount),
                        icon: "trash.fill",
                        valueColor: .primary
                    )
                }

                recommendations

                if !activeItems.isEmpty {
                    recentServices
                }
            }
            .padding(24)
        }
        .background(Theme.background.opacity(0.35))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                Text(loc.t("db_title"))
                    .font(Theme.titleFont())

                Text(activeItems.isEmpty ? loc.t("db_quiet") : String(format: loc.t("db_monitoring"), activeItems.count))
                    .font(Theme.bodyFont())
                    .foregroundColor(.secondary)
            }

            Spacer()

            BadgeView(
                text: exposedServicesCount > 0 ? loc.t("db_stat_exposed") : loc.t("db_clean_calm"),
                color: exposedServicesCount > 0 ? Theme.warningColor : Theme.safeColor,
                icon: exposedServicesCount > 0 ? "wifi.exclamationmark" : "checkmark.circle.fill"
            )
        }
    }

    private var recommendations: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.t("db_recommendations"))
                .font(Theme.sectionFont())

            VStack(spacing: 10) {
                if exposedServicesCount > 0 {
                    RecommendationRow(
                        title: loc.t("db_rec_exposed_title"),
                        description: String(format: loc.t("db_rec_exposed_desc"), exposedServicesCount),
                        actionText: loc.t("db_rec_exposed_btn"),
                        icon: "exclamationmark.triangle.fill",
                        actionType: .warning,
                        action: onNavigateToPorts
                    )
                }

                if trashInfo.sizeBytes > 0 {
                    RecommendationRow(
                        title: loc.t("db_rec_space_title"),
                        description: String(format: loc.t("db_rec_space_desc"), trashInfo.formattedSize),
                        actionText: loc.t("db_rec_space_btn"),
                        icon: "trash",
                        actionType: .normal,
                        action: onEmptyTrash
                    )
                }

                if !activeItems.isEmpty {
                    RecommendationRow(
                        title: loc.t("db_rec_clean_title"),
                        description: loc.t("db_rec_clean_desc"),
                        actionText: loc.t("db_rec_clean_btn"),
                        icon: "stop.circle.fill",
                        actionType: .primary,
                        action: onNavigateToPorts
                    )
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Theme.safeColor)

                        Text(loc.t("db_clean_calm"))
                            .font(Theme.sectionFont())

                        Spacer()
                    }
                    .portDeckCard(cornerRadius: Theme.controlRadius, padding: 16)
                }
            }
        }
    }

    private var recentServices: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(loc.t("db_recent_services"))
                    .font(Theme.sectionFont())

                Spacer()

                Button(action: onNavigateToPorts) {
                    Label(loc.t("db_rec_exposed_btn"), systemImage: "arrow.right")
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }

            VStack(spacing: 8) {
                ForEach(activeItems.prefix(5)) { item in
                    PortListRow(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onNavigateToPorts)
                        .portDeckCard(cornerRadius: Theme.controlRadius, padding: 12)
                }
            }
        }
    }
}

struct DashboardStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    var valueColor: Color = .primary
    var action: (() -> Void)? = nil

    var body: some View {
        if let action {
            Button(action: action) {
                card
            }
            .buttonStyle(.plain)
        } else {
            card
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(title)
                    .font(Theme.captionFont())
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(valueColor)
            }

            Spacer(minLength: 6)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(subtitle)
                .font(Theme.captionFont())
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minHeight: 120, alignment: .topLeading)
        .contentShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .portDeckCard()
    }
}

struct RecommendationRow: View {
    let title: String
    let description: String
    let actionText: String
    let icon: String
    let actionType: ActionType
    let action: () -> Void

    enum ActionType {
        case primary
        case warning
        case normal
    }

    private var accentColor: Color {
        switch actionType {
        case .primary: return Theme.primary
        case .warning: return Theme.warningColor
        case .normal: return .secondary
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(accentColor)
                .frame(width: 30, height: 30)
                .background(accentColor.opacity(0.13))
                .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)

                Text(description)
                    .font(Theme.bodyFont())
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            actionButton
        }
        .portDeckCard(cornerRadius: Theme.controlRadius, padding: 14)
    }

    @ViewBuilder
    private var actionButton: some View {
        switch actionType {
        case .primary:
            Button(action: action) {
                Label(actionText, systemImage: "arrow.right")
            }
            .buttonStyle(PrimaryActionButtonStyle())
        case .warning:
            Button(action: action) {
                Label(actionText, systemImage: "exclamationmark.triangle")
            }
            .buttonStyle(SecondaryActionButtonStyle(foregroundColor: Theme.warningColor))
        case .normal:
            Button(action: action) {
                Label(actionText, systemImage: "arrow.right")
            }
            .buttonStyle(SecondaryActionButtonStyle())
        }
    }
}
