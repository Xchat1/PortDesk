import SwiftUI

struct ProcessDetailDrawer: View {
    let item: PortServiceItem
    let isStopping: Bool
    let showForceStop: Bool
    let countdown: Int
    let onStop: (Bool) -> Void
    let onClose: () -> Void

    @State private var showForceConfirmAlert = false
    @ObservedObject private var loc = Localization.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    riskSection

                    Divider()

                    processSection

                    if let cwd = item.cwd, !cwd.isEmpty {
                        Divider()
                        DetailTextSection(
                            title: loc.t("detail_prop_cwd"),
                            text: cwd,
                            actions: {
                                CopyButton(textToCopy: cwd)

                                Button(action: { openInTerminal(at: cwd) }) {
                                    Label(loc.t("detail_btn_terminal"), systemImage: "terminal")
                                }
                                .buttonStyle(.borderless)

                                Button(action: {
                                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: cwd)
                                }) {
                                    Label(loc.t("detail_btn_reveal"), systemImage: "folder")
                                }
                                .buttonStyle(.borderless)
                            }
                        )
                    }

                    if let path = item.path, !path.isEmpty {
                        Divider()
                        DetailTextSection(
                            title: loc.t("detail_prop_path"),
                            text: path,
                            actions: {
                                CopyButton(textToCopy: path)
                            }
                        )
                    }

                    if let commandLine = item.commandLine, !commandLine.isEmpty {
                        Divider()
                        DetailTextSection(
                            title: loc.t("detail_prop_args"),
                            text: commandLine,
                            lineLimit: 4,
                            actions: {
                                CopyButton(textToCopy: commandLine)
                            }
                        )
                    }
                }
                .padding(16)
                .padding(.bottom, 8)
            }

            Divider()

            footer
        }
        .frame(width: 380)
        .background(Theme.surface)
        .alert(forceStopTitle, isPresented: $showForceConfirmAlert) {
            Button(forceStopConfirmText, role: .destructive) {
                onStop(true)
            }
            Button(loc.t("alert_cancel"), role: .cancel) {}
        } message: {
            Text(forceStopMessage)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: FrameworkSymbol.name(for: item.framework))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.primary)
                .frame(width: 38, height: 38)
                .background(Theme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.processName)
                    .font(Theme.cardTitleFont())
                    .lineLimit(1)

                Text("\(item.protocolName) \(item.host):\(item.ports.map { String($0) }.joined(separator: ", "))")
                    .font(Theme.monoFont())
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                ServiceStatusBadge(item: item)
            }

            Spacer(minLength: 8)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Theme.surfaceVariant.opacity(0.7))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help(loc.currentLanguage == .chinese ? "关闭详情" : "Close details")
        }
        .padding(16)
    }

    private var riskSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DetailSectionTitle(loc.t("detail_risk_title"))

            HStack(spacing: 8) {
                if item.isSystemProcess {
                    BadgeView(text: loc.t("detail_badge_system"), color: Theme.safeColor, icon: "cpu.fill")
                } else if item.isAppleSigned {
                    BadgeView(text: loc.t("detail_badge_apple"), color: Theme.safeColor, icon: "checkmark.seal.fill")
                } else {
                    BadgeView(text: loc.t("detail_badge_dev"), color: Theme.primary, icon: "hammer.fill")
                }

                if item.isLocalOnly {
                    BadgeView(text: loc.t("detail_badge_local"), color: Theme.safeColor, icon: "lock.fill")
                } else {
                    BadgeView(text: loc.t("detail_badge_exposed"), color: Theme.warningColor, icon: "wifi.exclamationmark")
                }
            }

            Text(getRiskDescription(item))
                .font(Theme.bodyFont())
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var processSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailSectionTitle(loc.t("detail_info_title"))

            PropertyRow(label: loc.t("detail_prop_name"), value: item.processName)
            PropertyRow(label: loc.t("detail_prop_pid"), value: "\(item.pid)", mono: true)
            PropertyRow(label: loc.t("detail_prop_ppid"), value: "\(item.ppid)", mono: true)
            PropertyRow(label: loc.t("detail_prop_user"), value: item.userName)
            PropertyRow(label: loc.t("detail_prop_addr"), value: "\(item.host):\(item.ports.map { String($0) }.joined(separator: ", "))", mono: true)

            if let parent = item.parentProcessName {
                PropertyRow(label: loc.t("detail_prop_parent"), value: parent)
            }

            if let browserURL = localBrowserURL {
                HStack {
                    Spacer()
                    Button(action: { NSWorkspace.shared.open(browserURL) }) {
                        Label(loc.t("detail_btn_open_browser"), systemImage: "safari")
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            if item.isProtected {
                HStack(spacing: 8) {
                    Image(systemName: "shield.fill")
                        .foregroundColor(Theme.warningColor)

                    Text(loc.t("detail_system_protected"))
                        .font(Theme.captionFont())
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(12)
                .background(Theme.surfaceVariant.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
            } else if isStopping {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)

                    Text(String(format: loc.t("detail_stopping"), countdown))
                        .font(Theme.bodyFont())
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.vertical, 8)
            } else if showForceStop {
                Button(action: { showForceConfirmAlert = true }) {
                    Label(loc.t("detail_btn_force"), systemImage: "xmark.octagon.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(DestructiveActionButtonStyle())

                Text(loc.t("detail_force_warn"))
                    .font(Theme.captionFont())
                    .foregroundColor(Theme.dangerColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Button(action: { onStop(false) }) {
                    Label(loc.t("detail_btn_stop"), systemImage: "stop.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
        .padding(16)
        .background(Theme.surface.opacity(0.96))
    }

    private var localBrowserURL: URL? {
        guard item.isLocalOnly, let port = item.ports.first else { return nil }
        return URL(string: "http://127.0.0.1:\(port)")
    }

    private var forceStopTitle: String {
        loc.currentLanguage == .chinese ? "强制结束服务？" : "Force Kill Service?"
    }

    private var forceStopMessage: String {
        loc.currentLanguage == .chinese
            ? "将立即对 \(item.processName) (PID \(item.pid)) 发送 SIGKILL。此操作不会给服务清理资源的机会。"
            : "This sends SIGKILL to \(item.processName) (PID \(item.pid)) immediately. The service will not get a chance to clean up resources."
    }

    private var forceStopConfirmText: String {
        loc.currentLanguage == .chinese ? "强制结束" : "Force Kill"
    }

    private func openInTerminal(at path: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Terminal", path]
        try? process.run()
    }

    private func getRiskDescription(_ item: PortServiceItem) -> String {
        if item.isSystemProcess {
            return loc.currentLanguage == .chinese ? "这是 macOS 系统服务。它受 Apple 保护，对系统正常运行至关重要。" : "This is a macOS system service. It is protected by Apple and is critical for normal system operations."
        }
        if item.isAppleSigned {
            return loc.currentLanguage == .chinese ? "此进程由 Apple 签名。它很可能是标准实用程序或系统应用程序。" : "This process is signed by Apple. It is likely a standard utility or system application."
        }
        if item.isLocalOnly {
            return loc.currentLanguage == .chinese ? "只有运行在此 Mac 上的应用程序才能连接到此端口。不受外部网络攻击威胁。" : "Only applications running on this Mac can connect to this port. It is safe from external network attacks."
        }
        return loc.currentLanguage == .chinese ? "警告：此端口对当前局域网（Wi-Fi/LAN）中的所有设备开放。在暴露前，请确认您信任此部署。" : "Warning: This port is open to all devices in the current local network (Wi-Fi/LAN). Confirm you trust this deployment before exposing it."
    }
}

struct DetailSectionTitle: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }
}

struct DetailTextSection<Actions: View>: View {
    let title: String
    let text: String
    var lineLimit: Int? = 2
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                DetailSectionTitle(title)
                Spacer()
                actions()
            }

            MonoBlock(text: text, lineLimit: lineLimit)
        }
    }
}

struct PropertyRow: View {
    let label: String
    let value: String
    var mono: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .font(Theme.captionFont())
                .foregroundColor(.secondary)
                .frame(width: 118, alignment: .leading)

            Text(value)
                .font(mono ? Theme.monoFont() : Theme.bodyFont())
                .foregroundColor(.primary)
                .lineLimit(2)
                .truncationMode(.middle)

            Spacer(minLength: 0)
        }
    }
}

struct CopyButton: View {
    let textToCopy: String
    @State private var isCopied = false
    @ObservedObject private var loc = Localization.shared

    var body: some View {
        Button(action: {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(textToCopy, forType: .string)
            withAnimation {
                isCopied = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isCopied = false
                }
            }
        }) {
            Label(
                isCopied ? (loc.currentLanguage == .chinese ? "已复制" : "Copied") : loc.t("detail_btn_copy"),
                systemImage: isCopied ? "checkmark" : "doc.on.doc"
            )
            .font(.system(size: 11))
            .foregroundColor(isCopied ? Theme.safeColor : .primary)
        }
        .buttonStyle(.borderless)
    }
}
