import SwiftUI

struct SettingsView: View {
    @ObservedObject private var loc = Localization.shared
    @AppStorage("refresh_interval") private var refreshInterval: Double = 5.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                SettingsSection(
                    icon: "globe",
                    title: loc.currentLanguage == .chinese ? "界面语言" : "Interface Language"
                ) {
                    VStack(spacing: 8) {
                        ForEach(AppLanguage.allCases) { lang in
                            LanguageOptionRow(
                                language: lang,
                                isSelected: loc.currentLanguage == lang,
                                onSelect: {
                                    loc.currentLanguage = lang
                                }
                            )
                        }
                    }
                }

                SettingsSection(
                    icon: "timer",
                    title: loc.currentLanguage == .chinese ? "刷新频率" : "Refresh Interval"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(loc.currentLanguage == .chinese
                             ? "自动扫描活跃端口的间隔。长时间间隔适合挂机省电；需要即时监控时请选择秒级。"
                             : "How often PortDeck auto-scans active ports. Long intervals save power when idle; use seconds for live monitoring.")
                            .font(Theme.bodyFont())
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            Picker("", selection: $refreshInterval) {
                                ForEach(RefreshInterval.options, id: \.self) { seconds in
                                    Text(RefreshInterval.label(
                                        seconds: seconds,
                                        chinese: loc.currentLanguage == .chinese
                                    ))
                                    .tag(seconds)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .frame(maxWidth: 220, alignment: .leading)

                            Text(RefreshInterval.label(
                                seconds: refreshInterval,
                                chinese: loc.currentLanguage == .chinese
                            ))
                            .font(Theme.captionFont())
                            .foregroundColor(.secondary)

                            Spacer(minLength: 0)
                        }

                        if refreshInterval <= 0 {
                            Text(loc.currentLanguage == .chinese
                                 ? "当前为仅手动刷新，可点击工具栏刷新按钮更新数据。"
                                 : "Manual mode only — use the toolbar refresh button to update data.")
                                .font(Theme.captionFont())
                                .foregroundColor(.secondary)
                        } else if refreshInterval >= 3600 {
                            Text(loc.currentLanguage == .chinese
                                 ? "应用处于睡眠/被挂起时，长间隔定时器会延后到唤醒后触发。"
                                 : "If macOS suspends the app, long-interval timers fire after it wakes.")
                                .font(Theme.captionFont())
                                .foregroundColor(.secondary)
                        }
                    }
                    .onAppear {
                        // Migrate unknown legacy values to the nearest supported option.
                        if !RefreshInterval.options.contains(refreshInterval) {
                            refreshInterval = RefreshInterval.options.min(by: {
                                abs($0 - refreshInterval) < abs($1 - refreshInterval)
                            }) ?? 5.0
                        }
                    }
                }

                SettingsSection(
                    icon: "info.circle",
                    title: loc.currentLanguage == .chinese ? "关于" : "About"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        AboutRow(
                            label: loc.currentLanguage == .chinese ? "应用名称" : "App Name",
                            value: "PortDeck"
                        )
                        AboutRow(
                            label: loc.currentLanguage == .chinese ? "版本" : "Version",
                            value: AppInfo.version
                        )
                        AboutRow(
                            label: loc.currentLanguage == .chinese ? "架构" : "Architecture",
                            value: "Apple Silicon (arm64)"
                        )
                        AboutRow(
                            label: loc.currentLanguage == .chinese ? "支持系统" : "Requires",
                            value: "macOS 14.0+"
                        )

                        Divider()

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(Theme.safeColor)
                                .font(.system(size: 12, weight: .semibold))

                            Text(loc.currentLanguage == .chinese
                                 ? "PortDeck 不常驻后台，不需要管理员权限，不上传任何数据。"
                                 : "PortDeck runs no background daemons, requires no admin access, and uploads no data.")
                                .font(Theme.captionFont())
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.background.opacity(0.28))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(loc.currentLanguage == .chinese ? "偏好设置" : "Preferences")
                .font(Theme.titleFont())

            Text(loc.currentLanguage == .chinese ? "自定义 PortDeck 的语言和行为" : "Customize PortDeck language and behavior")
                .font(Theme.bodyFont())
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsSection<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.primary)
                    .frame(width: 20)

                Text(title)
                    .font(Theme.sectionFont())
            }

            content()
        }
        .portDeckCard(padding: 18)
    }
}

struct LanguageOptionRow: View {
    let language: AppLanguage
    let isSelected: Bool
    let onSelect: () -> Void

    @ObservedObject private var loc = Localization.shared

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(isSelected ? Theme.primary : .secondary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(language.displayName)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(Theme.captionFont())
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    BadgeView(
                        text: loc.currentLanguage == .chinese ? "当前语言" : "Current",
                        color: Theme.primary,
                        icon: "checkmark"
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Theme.primary.opacity(0.08) : Theme.surfaceVariant.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                    .stroke(isSelected ? Theme.primary.opacity(0.35) : Theme.border.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var subtitle: String {
        switch (loc.currentLanguage, language) {
        case (.chinese, .chinese): return "Chinese (Simplified)"
        case (.chinese, .english): return "English"
        case (.english, .chinese): return "Simplified Chinese"
        case (.english, .english): return "English"
        }
    }
}

struct AboutRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(Theme.captionFont())
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(Theme.bodyFont())
                .foregroundColor(.primary)

            Spacer()
        }
    }
}
