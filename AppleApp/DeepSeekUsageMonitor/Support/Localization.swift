import Foundation

enum L10nKey: String {
    case usageMonitor
    case autoRefresh
    case mockMode
    case live
    case refresh
    case balanceRemaining
    case today
    case total
    case uptime
    case todayRequests
    case todayTokens
    case todaySpend
    case totalSpend
    case modelUsageToday
    case recentRequests
    case settings
    case deepseekApiKey
    case configuredLocally
    case notConfigured
    case enterNewApiKey
    case initialTotalCredit
    case save
    case saved
    case saving
    case invalidCredit
    case apiKeyMissing
    case liveBalanceLoaded
    case liveUsageUnavailable
    case balanceLoadFailed
    case estimateNote
    case language
    case theme
    case focusMode
    case system
    case dark
    case light
    case refreshInterval
    case gaugeRange
    case clearKey
    case tokens
}

private let zhStrings: [L10nKey: String] = [
    .usageMonitor: "用量监控",
    .autoRefresh: "自动刷新",
    .mockMode: "模拟数据",
    .live: "在线",
    .refresh: "刷新",
    .balanceRemaining: "剩余额度",
    .today: "今日",
    .total: "累计",
    .uptime: "运行时长",
    .todayRequests: "今日请求",
    .todayTokens: "今日 Token",
    .todaySpend: "今日消费",
    .totalSpend: "累计消费",
    .modelUsageToday: "今日模型用量",
    .recentRequests: "最近请求",
    .settings: "设置",
    .deepseekApiKey: "DeepSeek API 密钥",
    .configuredLocally: "本机已配置 API 密钥",
    .notConfigured: "未配置",
    .enterNewApiKey: "输入新的 API 密钥",
    .initialTotalCredit: "初始总额度",
    .save: "保存",
    .saved: "已保存",
    .saving: "保存中...",
    .invalidCredit: "无效的额度数值",
    .apiKeyMissing: "未配置 API Key，当前显示安全的模拟数据。",
    .liveBalanceLoaded: "已读取 DeepSeek 真实余额。",
    .liveUsageUnavailable: "官方暂未提供实时用量字段，今日用量不显示。",
    .balanceLoadFailed: "读取余额失败，当前显示模拟数据。",
    .estimateNote: "累计消费为估算值：初始总额度 - 当前余额。",
    .language: "语言",
    .theme: "主题",
    .focusMode: "专注模式",
    .system: "跟随系统",
    .dark: "深色",
    .light: "浅色",
    .refreshInterval: "刷新间隔",
    .gaugeRange: "仪表盘范围",
    .clearKey: "清除密钥",
    .tokens: "Token"
]

private let enStrings: [L10nKey: String] = [
    .usageMonitor: "Usage Monitor",
    .autoRefresh: "Auto Refresh",
    .mockMode: "Mock Data",
    .live: "Live",
    .refresh: "Refresh",
    .balanceRemaining: "Balance Remaining",
    .today: "Today",
    .total: "Total",
    .uptime: "Uptime",
    .todayRequests: "Today Requests",
    .todayTokens: "Today Tokens",
    .todaySpend: "Today Spend",
    .totalSpend: "Total Spend",
    .modelUsageToday: "Model Usage Today",
    .recentRequests: "Recent Requests",
    .settings: "Settings",
    .deepseekApiKey: "DeepSeek API Key",
    .configuredLocally: "Configured locally",
    .notConfigured: "Not configured",
    .enterNewApiKey: "Enter new API key",
    .initialTotalCredit: "Initial Total Credit",
    .save: "Save",
    .saved: "Saved",
    .saving: "Saving...",
    .invalidCredit: "Invalid credit value",
    .apiKeyMissing: "API key is not configured. Showing safe mock data.",
    .liveBalanceLoaded: "Loaded live DeepSeek balance.",
    .liveUsageUnavailable: "Official real-time usage fields are unavailable; today usage is not displayed.",
    .balanceLoadFailed: "Balance refresh failed. Showing mock data.",
    .estimateNote: "Total spend is estimated: initial total credit - current balance.",
    .language: "Language",
    .theme: "Theme",
    .focusMode: "Focus",
    .system: "System",
    .dark: "Dark",
    .light: "Light",
    .refreshInterval: "Refresh Interval",
    .gaugeRange: "Gauge Range",
    .clearKey: "Clear Key",
    .tokens: "Tokens"
]

extension AppLanguage {
    func text(_ key: L10nKey) -> String {
        switch self {
        case .zh:
            return zhStrings[key] ?? enStrings[key] ?? key.rawValue
        case .en:
            return enStrings[key] ?? key.rawValue
        }
    }
}
