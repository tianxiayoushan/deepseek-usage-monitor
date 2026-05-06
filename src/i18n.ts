// src/i18n.ts

export type Language = "zh" | "en";

export const translations = {
  en: {
    // Header & Global
    usageMonitor: "USAGE MONITOR",
    autoRefresh: "AUTO REFRESH",
    mockMode: "MOCK MODE",
    live: "LIVE",
    rec: "REC",
    refresh: "REFRESH",
    refresh_s: "REFRESH 5S",
    
    // CircularGauge
    balanceRemaining: "BALANCE REMAINING",
    today: "TODAY",
    total: "TOTAL",
    uptime: "UPTIME",
    online: "LIVE",
    
    // MetricCards
    todayRequests: "TODAY REQUESTS",
    todayTokens: "TODAY TOKENS",
    todaySpend: "TODAY SPEND",
    totalSpend: "TOTAL SPEND",
    cumulative: "CUMULATIVE",
    
    // Right Panel
    modelUsageToday: "MODEL USAGE TODAY",
    recentRequests: "RECENT REQUESTS",
    last5: "LAST 5",
    
    // Table Headers
    time: "TIME",
    model: "MODEL",
    prompt: "PROMPT",
    comp: "COMP.",
    completion: "COMPLETION",
    total_tokens: "TOTAL",
    cost: "COST",
    status: "STATUS",
    latency: "LATENCY",
    success: "SUCCESS",
    error: "ERROR",
    
    // SettingsPanel
    settings: "SETTINGS",
    deepseekApiKey: "DEEPSEEK API KEY",
    configuredLocally: "Configured locally",
    notConfigured: "Not configured",
    enterNewApiKey: "Enter new API key",
    initialTotalCredit: "INITIAL TOTAL CREDIT",
    save: "SAVE",
    saving: "SAVING...",
    saved: "SAVED",
    saveError: "ERROR",
    invalidCredit: "Invalid credit value",
    backendOffline: "Backend offline — start uvicorn on port 8789",
    overrideNote: "Enter a new API key to override the current one.",
    creditNote: "Used to estimate historical total spend: initial credit − current balance.",
    estimateNote: "Total Spend is an estimate only. Does not account for refunds, granted credits, currency changes, or admin adjustments.",
    
    // Tooltips / Aria
    hidePanel: "Hide panel",
    showPanel: "Show panel",
    toggleTheme: "Toggle theme",
    openSettings: "Open settings",
    closeSettings: "Close settings",
    changeLanguage: "Change language",
    gaugeRange: "GAUGE RANGE",
    maxAmount: "MAX AMOUNT",
    adjustGaugeMax: "Adjust gauge max amount",
  },
  zh: {
    // Header & Global
    usageMonitor: "用量监控",
    autoRefresh: "自动刷新",
    mockMode: "模拟模式",
    live: "在线",
    rec: "记录",
    refresh: "刷新",
    refresh_s: "刷新 5 秒",
    
    // CircularGauge
    balanceRemaining: "剩余额度",
    today: "今日",
    total: "累计",
    uptime: "运行时长",
    online: "在线",
    
    // MetricCards
    todayRequests: "今日请求",
    todayTokens: "今日 Token",
    todaySpend: "今日消费",
    totalSpend: "累计消费",
    cumulative: "累计",
    
    // Right Panel
    modelUsageToday: "今日模型用量",
    recentRequests: "最近请求",
    last5: "最近 5 条",
    
    // Table Headers
    time: "时间",
    model: "模型",
    prompt: "输入",
    comp: "输出",
    completion: "完成",
    total_tokens: "合计",
    cost: "费用",
    status: "状态",
    latency: "延迟",
    success: "成功",
    error: "错误",
    
    // SettingsPanel
    settings: "设置",
    deepseekApiKey: "DeepSeek API 密钥",
    configuredLocally: "本机已配置 API 密钥",
    notConfigured: "未配置",
    enterNewApiKey: "输入新的 API 密钥",
    initialTotalCredit: "初始总额度",
    save: "保存",
    saving: "保存中...",
    saved: "已保存",
    saveError: "错误",
    invalidCredit: "无效的额度数值",
    backendOffline: "后端离线 — 请在 8789 端口启动 uvicorn",
    overrideNote: "输入新的 API 密钥以覆盖当前配置。",
    creditNote: "用于估算历史累计消费：初始额度 - 当前余额。",
    estimateNote: "累计消费仅为估算值，不包含退款、赠余额度、币种变化或后台调整。",
    
    // Tooltips / Aria
    hidePanel: "隐藏面板",
    showPanel: "显示面板",
    toggleTheme: "切换主题",
    openSettings: "打开设置",
    closeSettings: "关闭设置",
    changeLanguage: "切换语言",
    gaugeRange: "仪表盘范围",
    maxAmount: "最大金额",
    adjustGaugeMax: "调整仪表盘最大金额",
  }
};

export type TranslationKeys = keyof typeof translations.en;

export const t = (lang: Language, key: TranslationKeys): string => {
  return translations[lang][key] || translations.en[key] || key;
};
