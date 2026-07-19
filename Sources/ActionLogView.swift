import SwiftUI

struct ActionLogView: View {
    private let pageSize = 20

    @State private var logs: [ActionLogItem] = []
    @State private var page: Int = 1
    @State private var pendingDeleteID: String? = nil
    @State private var showClearAlert = false

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
                List(pagedLogs) { log in
                    ActionLogRow(
                        log: log,
                        onDelete: { pendingDeleteID = log.id }
                    )
                    .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                paginationFooter
            }
        }
        .background(Theme.background.opacity(0.28))
        .onAppear(perform: refresh)
        // Confirm single-entry deletion
        .alert(loc.t("logs_delete_title"), isPresented: Binding(
            get: { pendingDeleteID != nil },
            set: { if !$0 { pendingDeleteID = nil } }
        )) {
            Button(loc.t("logs_delete_confirm"), role: .destructive) {
                if let id = pendingDeleteID {
                    performDelete(id)
                }
                pendingDeleteID = nil
            }
            Button(loc.t("alert_cancel"), role: .cancel) {
                pendingDeleteID = nil
            }
        } message: {
            Text(loc.t("logs_delete_desc"))
        }
        // Confirm clear all
        .alert(loc.t("logs_clear_title"), isPresented: $showClearAlert) {
            Button(loc.t("logs_clear_confirm"), role: .destructive) {
                clearAll()
            }
            Button(loc.t("alert_cancel"), role: .cancel) {}
        } message: {
            Text(String(format: loc.t("logs_clear_desc"), logs.count))
        }
    }

    // MARK: - Header

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

            Button(action: { showClearAlert = true }) {
                Label(loc.t("logs_btn_clear"), systemImage: "trash")
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .disabled(logs.isEmpty)

            Button(action: refresh) {
                Label(loc.t("logs_btn_refresh"), systemImage: "arrow.clockwise")
            }
            .buttonStyle(SecondaryActionButtonStyle())
        }
        .padding(24)
    }

    // MARK: - Pagination

    private var totalPages: Int {
        max(1, Int((Double(logs.count) / Double(pageSize)).rounded(.up)))
    }

    private var safePage: Int {
        min(max(1, page), totalPages)
    }

    private var pagedLogs: [ActionLogItem] {
        let start = (safePage - 1) * pageSize
        let end = min(start + pageSize, logs.count)
        guard start < end else { return [] }
        return Array(logs[start..<end])
    }

    private var paginationFooter: some View {
        HStack(spacing: 12) {
            Button(action: { page = max(1, safePage - 1) }) {
                Label(loc.t("logs_prev"), systemImage: "chevron.left")
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .disabled(safePage <= 1)

            Text(String(format: loc.t("logs_page"), safePage, totalPages))
                .font(Theme.captionFont())
                .foregroundColor(.secondary)
                .frame(minWidth: 90)

            Button(action: { page = min(totalPages, safePage + 1) }) {
                Label(loc.t("logs_next"), systemImage: "chevron.right")
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .disabled(safePage >= totalPages)

            Spacer()

            Text(String(format: loc.t("logs_total"), logs.count))
                .font(Theme.captionFont())
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Theme.surface.opacity(0.5))
    }

    // MARK: - Data operations

    private func refresh() {
        ActionLogService.shared.loadLogs { logs in
            self.logs = logs
            self.page = 1
        }
    }

    private func performDelete(_ id: String) {
        ActionLogService.shared.deleteLog(id: id)
        logs.removeAll { $0.id == id }
        page = safePage
    }

    private func clearAll() {
        ActionLogService.shared.clearLogs {
            self.logs = []
            self.page = 1
        }
    }
}

struct ActionLogRow: View {
    let log: ActionLogItem
    let onDelete: () -> Void

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

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.dangerColor)
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(.plain)
                .help(loc.currentLanguage == .chinese ? "删除这条记录" : "Delete this entry")
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
