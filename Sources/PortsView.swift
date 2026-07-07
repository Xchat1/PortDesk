import SwiftUI

struct PortsView: View {
    let items: [PortServiceItem]
    @Binding var selectedItem: PortServiceItem?

    @State private var searchQuery = ""
    @State private var riskFilter: RiskFilter = .all
    @State private var layoutMode: LayoutMode = .cards

    @ObservedObject private var loc = Localization.shared

    enum RiskFilter: String, CaseIterable, Identifiable {
        case all
        case exposed
        case local
        case system

        var id: String { rawValue }

        var localizedName: String {
            switch self {
            case .all: return Localization.shared.t("ports_filter_all")
            case .exposed: return Localization.shared.t("ports_filter_exposed")
            case .local: return Localization.shared.t("ports_filter_local")
            case .system: return Localization.shared.t("ports_filter_system")
            }
        }
    }

    enum LayoutMode {
        case cards
        case list
    }

    var filteredItems: [PortServiceItem] {
        items.filter { item in
            let query = searchQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty ||
                item.processName.lowercased().contains(query) ||
                item.ports.map { String($0) }.joined(separator: ",").contains(query) ||
                "\(item.pid)".contains(query) ||
                item.framework.lowercased().contains(query) ||
                (item.cwd?.lowercased().contains(query) ?? false) ||
                (item.commandLine?.lowercased().contains(query) ?? false)

            let matchesFilter: Bool
            switch riskFilter {
            case .all:
                matchesFilter = true
            case .exposed:
                matchesFilter = !item.isLocalOnly && !item.isSystemProcess
            case .local:
                matchesFilter = item.isLocalOnly && !item.isSystemProcess
            case .system:
                matchesFilter = item.isSystemProcess || item.isAppleSigned
            }

            return matchesSearch && matchesFilter
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar

            Divider()

            if filteredItems.isEmpty {
                EmptyStateView(
                    icon: "network.slash",
                    title: loc.t("ports_empty")
                )
            } else if layoutMode == .cards {
                cardGrid
            } else {
                portList
            }
        }
        .background(Theme.background.opacity(0.28))
    }

    private var filterBar: some View {
        HStack(spacing: 14) {
            searchField

            Picker("", selection: $riskFilter) {
                ForEach(RiskFilter.allCases) { filter in
                    Text(filter.localizedName).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 360)

            Spacer(minLength: 12)

            Picker("", selection: $layoutMode) {
                Image(systemName: "square.grid.2x2.fill").tag(LayoutMode.cards)
                Image(systemName: "list.bullet").tag(LayoutMode.list)
            }
            .pickerStyle(.segmented)
            .frame(width: 84)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Theme.surface.opacity(0.75))
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            TextField(loc.t("ports_search_placeholder"), text: $searchQuery)
                .textFieldStyle(.plain)
                .font(Theme.bodyFont())

            if !searchQuery.isEmpty {
                Button(action: { searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help(loc.currentLanguage == .chinese ? "清除搜索" : "Clear search")
            }
        }
        .padding(.horizontal, 11)
        .frame(height: 32)
        .background(Theme.surfaceVariant.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                .stroke(Theme.border.opacity(0.55), lineWidth: 1)
        )
        .frame(maxWidth: 340)
    }

    private var cardGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280, maximum: 420), spacing: 16, alignment: .top)], spacing: 16) {
                ForEach(filteredItems) { item in
                    PortCardView(item: item, isSelected: selectedItem?.id == item.id)
                        .contentShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                        .onTapGesture {
                            selectedItem = item
                        }
                }
            }
            .padding(20)
        }
    }

    private var portList: some View {
        List(filteredItems, selection: $selectedItem) { item in
            PortListRow(item: item)
                .tag(item)
                .padding(.vertical, 5)
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
    }
}

struct PortCardView: View {
    let item: PortServiceItem
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: FrameworkSymbol.name(for: item.framework))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.primary)
                    .frame(width: 30, height: 30)
                    .background(Theme.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.processName)
                        .font(Theme.cardTitleFont())
                        .lineLimit(1)

                    Text(item.framework)
                        .font(Theme.captionFont())
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                ServiceStatusBadge(item: item)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("@\(item.host):\(item.ports.map { String($0) }.joined(separator: ", "))")
                    .font(Theme.monoFont())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 6) {
                    Image(systemName: (item.cwd?.isEmpty == false) ? "folder" : "terminal")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text(projectLabel)
                        .font(Theme.captionFont())
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Divider()

            HStack(spacing: 12) {
                Text("PID \(item.pid)")
                    .font(Theme.monoFont())
                    .foregroundColor(.secondary)

                Text(item.userName)
                    .font(Theme.captionFont())
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()
            }
        }
        .frame(minHeight: 142, alignment: .top)
        .portDeckCard()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(isSelected ? Theme.primary : Color.clear, lineWidth: 2)
        )
    }

    private var projectLabel: String {
        if let cwd = item.cwd, !cwd.isEmpty {
            return URL(fileURLWithPath: cwd).lastPathComponent
        }

        return item.path ?? item.processName
    }
}

struct PortListRow: View {
    let item: PortServiceItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: FrameworkSymbol.name(for: item.framework))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.primary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(":\(item.ports.map { String($0) }.joined(separator: ","))")
                    .font(Theme.monoFont())
                    .foregroundColor(.primary)

                Text(item.host)
                    .font(Theme.captionFont())
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 118, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.processName)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)

                Text(item.framework)
                    .font(Theme.captionFont())
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 150, alignment: .leading)

            Text("PID \(item.pid)")
                .font(Theme.monoFont())
                .foregroundColor(.secondary)
                .frame(width: 88, alignment: .leading)

            Text(item.cwd?.isEmpty == false ? item.cwd! : (item.path ?? ""))
                .font(Theme.monoFont())
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 8)

            ServiceStatusBadge(item: item)
        }
    }
}
