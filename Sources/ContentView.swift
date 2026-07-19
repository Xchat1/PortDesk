import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: NavigationTab = .dashboard
    @State private var items: [PortServiceItem] = []
    @State private var trashInfo = TrashInfo(sizeBytes: 0, fileCount: 0)
    @State private var isScanning = false
    
    // Details drawer states
    @State private var selectedItem: PortServiceItem? = nil
    @State private var isStopping = false
    @State private var showForceStop = false
    @State private var stopCountdown = 3
    @State private var countdownTimer: Timer? = nil
    
    // Alert states
    @State private var showEmptyTrashAlert = false
    @State private var showStopConfirmAlert = false
    @State private var stopConfirmAction: (() -> Void)? = nil
    
    // Auto refresh timer
    @AppStorage("refresh_interval") private var refreshInterval: Double = 5.0
    @State private var refreshTimer: Timer? = nil
    
    @ObservedObject private var loc = Localization.shared
    @ObservedObject private var appearance = AppearanceManager.shared
    
    enum NavigationTab {
        case dashboard
        case ports
        case logs
        case settings
    }
    
    var exposedCount: Int {
        items.filter { !$0.isLocalOnly && !$0.isProtected }.count
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar Navigation
            List(selection: $selectedTab) {
                NavigationLink(value: NavigationTab.dashboard) {
                    Label(loc.t("nav_dashboard"), systemImage: "macwindow")
                }
                
                NavigationLink(value: NavigationTab.ports) {
                    Label(loc.t("nav_ports"), systemImage: "network")
                }
                
                NavigationLink(value: NavigationTab.logs) {
                    Label(loc.t("nav_logs"), systemImage: "doc.text")
                }
                
                Divider()
                
                NavigationLink(value: NavigationTab.settings) {
                    Label(loc.t("nav_language"), systemImage: "globe")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("PortDeck")
            
        } detail: {
            HStack(spacing: 0) {
                // Main Panel
                VStack(spacing: 0) {
                    // Toolbar
                    HStack {
                        if selectedTab == .ports {
                            Text(loc.currentLanguage == .chinese ? "活跃的本地服务" : "Active Local Services")
                                .font(Theme.titleFont())
                        }
                        
                        Spacer()
                        
                        // Appearance quick toggle (manual switching)
                        Menu {
                            ForEach(AppearanceMode.allCases) { mode in
                                Button {
                                    appearance.mode = mode
                                } label: {
                                    Label(appearanceLabel(for: mode),
                                          systemImage: mode == appearance.mode ? "checkmark" : "")
                                }
                            }
                        } label: {
                            Image(systemName: appearanceIcon)
                                .font(.system(size: 13, weight: .semibold))
                                .frame(width: 30, height: 30)
                                .background(Theme.surfaceVariant.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
                        }
                        .menuStyle(.borderlessButton)
                        .help(loc.currentLanguage == .chinese ? "外观" : "Appearance")
                        
                        // Status indicator
                        if isScanning {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.6)
                                Text(loc.currentLanguage == .chinese ? "扫描中..." : "Scanning...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.trailing, 8)
                        } else if let lastScan = appState.lastScanDate {
                            Text(String(format: loc.t("toolbar_last_scan"), formattedScanTime(lastScan)))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.trailing, 8)
                        }
                        
                        Button(action: { refreshAllData(showIndicator: true) }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13, weight: .semibold))
                                .frame(width: 30, height: 30)
                                .background(Theme.surfaceVariant.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(isScanning)
                        .keyboardShortcut("r", modifiers: .command)
                        .help(loc.currentLanguage == .chinese ? "刷新 (⌘R)" : "Refresh (⌘R)")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Theme.surface.opacity(0.92))
                    
                    Divider()
                    
                    // Body Views
                    switch selectedTab {
                    case .dashboard:
                        DashboardView(
                            activeItems: items,
                            exposedServicesCount: exposedCount,
                            trashInfo: trashInfo,
                            onNavigateToPorts: { selectedTab = .ports },
                            onEmptyTrash: { showEmptyTrashAlert = true }
                        )
                    case .ports:
                        PortsView(
                            items: items,
                            selectedItem: $selectedItem
                        )
                    case .logs:
                        ActionLogView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background.opacity(0.3))
                
                // Sidebar Details Drawer (Slides out from right)
                if let item = selectedItem, selectedTab == .ports {
                    Divider()
                    ProcessDetailDrawer(
                        item: item,
                        isStopping: isStopping,
                        showForceStop: showForceStop,
                        countdown: stopCountdown,
                        onStop: { force in
                            if force {
                                executeStop(item: item, force: true)
                            } else {
                                // Trigger SIGTERM warning or confirmation
                                showStopConfirmAlert = true
                                stopConfirmAction = {
                                    executeStop(item: item, force: false)
                                }
                            }
                        },
                        onClose: {
                            selectedItem = nil
                            resetStopStates()
                        }
                    )
                    .transition(.move(edge: .trailing))
                }
            }
        }
        .preferredColorScheme(appearance.resolvedColorScheme)
        .onAppear {
            refreshAllData()
            setupRefreshTimer()
        }
        .onDisappear {
            refreshTimer?.invalidate()
            countdownTimer?.invalidate()
        }
        .onChange(of: refreshInterval) {
            setupRefreshTimer()
        }
        .onChange(of: selectedTab) { _, tab in
            refreshForTab(tab, showIndicator: false)
        }
        .onReceive(NotificationCenter.default.publisher(for: .portDeckRefreshRequested)) { _ in
            refreshAllData(showIndicator: true)
        }
        // Confirmation alert for empty trash
        .alert(loc.t("alert_empty_trash_title"), isPresented: $showEmptyTrashAlert) {
            Button(loc.t("alert_empty_trash_confirm"), role: .destructive) {
                executeEmptyTrash()
            }
            Button(loc.t("alert_cancel"), role: .cancel) {}
        } message: {
            Text(loc.t("alert_empty_trash_desc"))
        }
        // Confirmation alert for stopping process
        .alert(loc.t("alert_stop_service_title"), isPresented: $showStopConfirmAlert) {
            Button(loc.t("alert_stop_service_confirm"), role: .destructive) {
                stopConfirmAction?()
            }
            Button(loc.t("alert_cancel"), role: .cancel) {}
        } message: {
            if let item = selectedItem {
                Text(String(format: loc.t("alert_stop_service_desc"), item.processName, item.pid, item.ports.first ?? 0))
            }
        }
    }
    
    // Refresh all services and values
    private func refreshAllData(showIndicator: Bool = true) {
        refreshPorts(showIndicator: showIndicator)
        refreshTrash()
    }

    private func refreshForTab(_ tab: NavigationTab, showIndicator: Bool) {
        switch tab {
        case .dashboard:
            refreshPorts(showIndicator: showIndicator)
            refreshTrash()
        case .ports:
            refreshPorts(showIndicator: showIndicator)
                    case .logs:
                        refreshPorts(showIndicator: showIndicator)
        case .settings:
            refreshPorts(showIndicator: showIndicator)
        }
    }

    private func refreshPorts(showIndicator: Bool) {
        if showIndicator {
            isScanning = true
            appState.isScanning = true
        }

        PortService.shared.scanActivePorts { scannedItems in
            if self.items != scannedItems {
                self.items = scannedItems
            }

            self.appState.activePortCount = scannedItems.count
            self.appState.exposedCount = scannedItems.filter { !$0.isLocalOnly && !$0.isProtected }.count
            self.appState.lastScanDate = Date()

            if let current = selectedItem, !scannedItems.contains(where: { $0.id == current.id }) {
                selectedItem = nil
                resetStopStates()
            }

            if showIndicator {
                self.isScanning = false
                self.appState.isScanning = false
            }
        }
    }

    private func refreshTrash() {
        TrashService.shared.scanTrashInfo { info in
            if self.trashInfo.sizeBytes != info.sizeBytes || self.trashInfo.fileCount != info.fileCount {
                self.trashInfo = info
            }
        }
    }
    
    private func setupRefreshTimer() {
        refreshTimer?.invalidate()
        guard refreshInterval > 0 else { return }

        let timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
            DispatchQueue.main.async {
                if !isScanning && !isStopping {
                    refreshForTab(selectedTab, showIndicator: false)
                }
            }
        }
        timer.tolerance = RefreshInterval.tolerance(for: refreshInterval)
        refreshTimer = timer
    }

    private func formattedScanTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    private func resetStopStates() {
        isStopping = false
        showForceStop = false
        stopCountdown = 3
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    private func executeStop(item: PortServiceItem, force: Bool) {
        if force {
            // Force Kill directly
            PortService.shared.stopService(item: item, force: true) { success in
                ActionLogService.shared.logAction(
                    type: "SIGKILL",
                    target: "PID \(item.pid) (\(item.processName)) on Port(s) \(item.ports.map { String($0) }.joined(separator: ","))",
                    details: "Command: \(item.commandLine ?? "Unknown"), Executable: \(item.path ?? "Unknown")",
                    status: success ? "Success" : "Failed"
                )
                
                if success {
                    selectedItem = nil
                    resetStopStates()
                    refreshAllData()
                }
            }
        } else {
            // Gentle SIGTERM
            isStopping = true
            stopCountdown = 3
            
            // Countdown timer
            countdownTimer?.invalidate()
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                DispatchQueue.main.async {
                    if self.stopCountdown > 1 {
                        self.stopCountdown -= 1
                    } else {
                        timer.invalidate()
                    }
                }
            }
            
            PortService.shared.stopService(item: item, force: false) { exited in
                countdownTimer?.invalidate()
                countdownTimer = nil
                isStopping = false
                
                ActionLogService.shared.logAction(
                    type: "SIGTERM",
                    target: "PID \(item.pid) (\(item.processName)) on Port(s) \(item.ports.map { String($0) }.joined(separator: ","))",
                    details: "Command: \(item.commandLine ?? "Unknown"), Executable: \(item.path ?? "Unknown")",
                    status: exited ? "Success" : "Process Active (Needs Kill)"
                )
                
                if exited {
                    selectedItem = nil
                    resetStopStates()
                    refreshAllData()
                } else {
                    showForceStop = true
                }
            }
        }
    }
    
    private func executeEmptyTrash() {
        TrashService.shared.emptyTrash { success in
            ActionLogService.shared.logAction(
                type: "Empty Trash",
                target: "System Trash",
                details: "Reclaimed approximately \(trashInfo.formattedSize)",
                status: success ? "Success" : "Failed"
            )
            
            TrashService.shared.scanTrashInfo { info in
                self.trashInfo = info
            }
        }
    }

    // MARK: - Appearance helpers

    private var appearanceIcon: String {
        switch appearance.mode {
        case .system:
            return appearance.systemScheme == .dark ? "circle.lefthalf.filled" : "sun.max"
        case .light:
            return "sun.max"
        case .dark:
            return "moon.fill"
        }
    }

    private func appearanceLabel(for mode: AppearanceMode) -> String {
        let chinese = loc.currentLanguage == .chinese
        switch mode {
        case .system: return chinese ? "跟随系统" : "System"
        case .light:  return chinese ? "浅色" : "Light"
        case .dark:   return chinese ? "深色" : "Dark"
        }
    }
}
