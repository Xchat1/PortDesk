import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case chinese = "zh"
    case english = "en"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .chinese: return "简体中文"
        case .english: return "English"
        }
    }
}

final class Localization: ObservableObject, @unchecked Sendable {
    static let shared = Localization()
    
    @AppStorage("app_language") var currentLanguage: AppLanguage = .chinese
    
    func t(_ key: String) -> String {
        let dict = currentLanguage == .chinese ? Localization.zh : Localization.en
        return dict[key] ?? key
    }
    
    // Translation dictionaries
    private static let zh: [String: String] = [
        // Sidebar Navigation
        "nav_dashboard": "控制面板",
        "nav_ports": "本地服务",
        "nav_logs": "操作日志",
        "nav_language": "语言设置",
        
        // Dashboard
        "db_title": "系统控制面板",
        "db_quiet": "您的 Mac 很安静。未发现活跃的本地开发服务。",
        "db_monitoring": "PortDeck 正在监控 %d 个活跃的本地开发服务。",
        "db_stat_active": "活跃服务",
        "db_stat_listening": "本地开发监听中",
        "db_stat_exposed": "对外监听",
        "db_stat_exposed_sub": "允许外部 IP 连接",
        "db_stat_trash": "回收站容量",
        "db_stat_trash_sub": "%d 个文件在废纸篓",
        "db_recommendations": "推荐操作",
        "db_rec_exposed_title": "局域网端口暴露警告",
        "db_rec_exposed_desc": "我们检测到有 %d 个服务对所有 IP 地址 (* / 0.0.0.0) 开放。同一局域网下的其他设备可以进行连接。",
        "db_rec_exposed_btn": "查看端口",
        "db_rec_space_title": "回收磁盘空间",
        "db_rec_space_desc": "废纸篓中积攒了 %@ 数据。清空废纸篓以释放空间。",
        "db_rec_space_btn": "清空回收站",
        "db_rec_clean_title": "清理残留服务",
        "db_rec_clean_desc": "一些开发服务器（如 Next.js、Ollama、PostgreSQL）可能在之前的开发会话中残留，仍在后台运行。",
        "db_rec_clean_btn": "清理残留服务",
        "db_clean_calm": "您的系统非常干净清爽！",
        "db_recent_services": "最近活跃服务",
        
        // PortsView
        "ports_search_placeholder": "搜索端口、PID、进程名、项目路径...",
        "ports_filter_all": "所有端口",
        "ports_filter_exposed": "局域网暴露",
        "ports_filter_local": "仅限本机",
        "ports_filter_system": "系统 / 苹果",
        "ports_empty": "没有符合当前筛选条件的本地服务。",
        "badge_system": "系统",
        "badge_exposed": "局域网暴露",
        "badge_local": "仅限本机",
        
        // SettingsView
        "settings_lang_title": "界面语言",
        "settings_lang_zh": "中文",
        "settings_lang_en": "英语",
        "settings_lang_cur": "当前语言",
        "settings_refresh_title": "刷新频率",
        "settings_refresh_desc": "应用后台自动扫描活跃端口的间隔时间。",
        "settings_about_title": "关于",
        
        // ProcessDetailDrawer
        "detail_title": "服务详情",
        "detail_risk_title": "风险与安全评估",
        "detail_badge_system": "系统进程",
        "detail_badge_apple": "Apple 签名",
        "detail_badge_dev": "开发者应用",
        "detail_badge_local": "仅限本机",
        "detail_badge_exposed": "局域网暴露",
        "detail_info_title": "进程详细信息",
        "detail_prop_name": "进程名称",
        "detail_prop_pid": "进程 PID",
        "detail_prop_ppid": "父进程 PID (PPID)",
        "detail_prop_user": "运行用户",
        "detail_prop_addr": "监听地址",
        "detail_prop_parent": "父进程",
        "detail_prop_cwd": "工作目录 (Cwd)",
        "detail_prop_path": "可执行程序路径",
        "detail_prop_args": "启动参数",
        "detail_btn_copy": "复制",
        "detail_btn_reveal": "定位",
        "detail_btn_terminal": "终端",
        "detail_btn_open_browser": "打开",
        "detail_system_protected": "系统进程受保护。PortDeck 无法关闭该服务。",
        "detail_stopping": "正在停止服务 (SIGTERM)... %ds",
        "detail_btn_force": "强制结束服务 (SIGKILL)",
        "detail_force_warn": "服务未及时关闭。您需要强制结束它。",
        "detail_btn_stop": "优雅关闭服务 (SIGTERM)",
        
        // ActionLogView
        "logs_title": "操作审计日志",
        "logs_btn_refresh": "刷新",
        "logs_empty_title": "暂无操作记录。",
        "logs_empty_desc": "关闭进程或清空回收站等敏感操作将记录在此。",
        "logs_prop_status": "操作状态:",
        
        // Alerts & Common
        "alert_empty_trash_title": "清空废纸篓？",
        "alert_empty_trash_desc": "确定要清空废纸篓吗？此操作无法撤销。",
        "alert_empty_trash_confirm": "清空废纸篓",
        "alert_stop_service_title": "关闭本地服务？",
        "alert_stop_service_desc": "确定关闭运行在端口 %3$d 的 %1$@ (PID %2$d)？",
        "alert_stop_service_confirm": "停止服务",
        "alert_cancel": "取消",

        // Toolbar & Menu Bar
        "toolbar_last_scan": "上次扫描 %@",
        "menubar_open": "打开 PortDeck",
        "menubar_active": "%d 个活跃服务",
        "menubar_exposed": "%d 个对外暴露",
        "menubar_last_scan": "上次扫描 %@",
        "menubar_refresh": "刷新",
        "menubar_quit": "退出 PortDeck"
    ]
    
    private static let en: [String: String] = [
        // Sidebar Navigation
        "nav_dashboard": "Dashboard",
        "nav_ports": "Local Services",
        "nav_logs": "Operation Logs",
        "nav_language": "Language",
        
        // Dashboard
        "db_title": "System Dashboard",
        "db_quiet": "Your Mac is quiet. No active local developer servers found.",
        "db_monitoring": "PortDeck is monitoring %d active local development service(s).",
        "db_stat_active": "Active Services",
        "db_stat_listening": "Listening Ports",
        "db_stat_exposed": "Network Exposure",
        "db_stat_exposed_sub": "Exposed to LAN (0.0.0.0)",
        "db_stat_trash": "Trash size",
        "db_stat_trash_sub": "%d files in Trash",
        "db_recommendations": "Recommendations",
        "db_rec_exposed_title": "External Port Exposure Alert",
        "db_rec_exposed_desc": "We detected %d service(s) exposed to all IP addresses (* / 0.0.0.0). Other devices on the same Wi-Fi network could connect to them.",
        "db_rec_exposed_btn": "Review Ports",
        "db_rec_space_title": "Reclaim Disk Space",
        "db_rec_space_desc": "There is %@ of data sitting in your trash. Empty the Trash to free up space.",
        "db_rec_space_btn": "Empty Trash",
        "db_rec_clean_title": "Clean Up Old Services",
        "db_rec_clean_desc": "Some developer servers (like Next.js, Ollama, PostgreSQL) might still be running in the background from previous sessions.",
        "db_rec_clean_btn": "Clean Up Now",
        "db_clean_calm": "Your system is clean & calm!",
        "db_recent_services": "Recent Services",
        
        // PortsView
        "ports_search_placeholder": "Search by port, PID, process name, project...",
        "ports_filter_all": "All Ports",
        "ports_filter_exposed": "LAN Exposed",
        "ports_filter_local": "Local Only",
        "ports_filter_system": "System / Apple",
        "ports_empty": "No local services matched your filters.",
        "badge_system": "System",
        "badge_exposed": "Exposed",
        "badge_local": "Local Only",
        
        // ProcessDetailDrawer
        "detail_title": "Service Details",
        "detail_risk_title": "Risk & Security Assessment",
        "detail_badge_system": "System Process",
        "detail_badge_apple": "Apple Signed",
        "detail_badge_dev": "Developer App",
        "detail_badge_local": "Local Host Only",
        "detail_badge_exposed": "LAN Exposed",
        "detail_info_title": "Process Information",
        "detail_prop_name": "Process Name",
        "detail_prop_pid": "Process PID",
        "detail_prop_ppid": "Parent PID (PPID)",
        "detail_prop_user": "Running User",
        "detail_prop_addr": "Address Bound",
        "detail_prop_parent": "Parent Process",
        "detail_prop_cwd": "Working Directory (Cwd)",
        "detail_prop_path": "Executable Path",
        "detail_prop_args": "Launch Arguments",
        "detail_btn_copy": "Copy",
        "detail_btn_reveal": "Reveal",
        "detail_btn_terminal": "Terminal",
        "detail_btn_open_browser": "Open",
        "detail_system_protected": "System processes are protected. PortDeck cannot shut down this service.",
        "detail_stopping": "Stopping service (SIGTERM)... %ds",
        "detail_btn_force": "Force Kill Service (SIGKILL)",
        "detail_force_warn": "The service did not close in time. You must force kill it.",
        "detail_btn_stop": "Gentle Stop Service (SIGTERM)",
        
        // ActionLogView
        "logs_title": "Operation Audit Logs",
        "logs_btn_refresh": "Refresh",
        "logs_empty_title": "No operations logged yet.",
        "logs_empty_desc": "Destructive actions like killing processes or emptying trash will be logged here.",
        "logs_prop_status": "Status:",
        
        // Alerts & Common
        "alert_empty_trash_title": "Empty Trash?",
        "alert_empty_trash_desc": "Are you sure you want to empty the Trash? This cannot be undone.",
        "alert_empty_trash_confirm": "Empty Trash",
        "alert_stop_service_title": "Stop Local Service?",
        "alert_stop_service_desc": "Confirm shutting down %@ (PID %d) on port %d?",
        "alert_stop_service_confirm": "Stop Service",
        "alert_cancel": "Cancel",

        // Toolbar & Menu Bar
        "toolbar_last_scan": "Last scan %@",
        "menubar_open": "Open PortDeck",
        "menubar_active": "%d active service(s)",
        "menubar_exposed": "%d exposed to LAN",
        "menubar_last_scan": "Last scan %@",
        "menubar_refresh": "Refresh",
        "menubar_quit": "Quit PortDeck"
    ]
}
