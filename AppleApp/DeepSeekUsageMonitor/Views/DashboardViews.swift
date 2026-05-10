import SwiftUI

struct DesktopDashboardView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(DashboardStore.self) private var dashboard
    @Environment(\.colorScheme) private var systemColorScheme

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    var body: some View {
        GeometryReader { proxy in
            let leftWidth = min(max(proxy.size.width * 0.48, 480), 720)

            HStack(spacing: 0) {
                GaugePanelView(isCompact: false)
                    .frame(width: leftWidth)
                    .background(palette.leftPanel)
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(palette.border.opacity(0.45))
                            .frame(width: 1)
                    }

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        StatusBanner()
                        MetricGridView(columns: 2)
                        ModelUsagePanel()
                        RecentRequestsPanel(limit: 5)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 24)
                }
                .background(
                    ZStack {
                        palette.rightPanel
                        DotGridBackground(color: palette.border.opacity(0.16), spacing: 18)
                    }
                )
            }
        }
    }
}

struct MobileDashboardView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var systemColorScheme

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GaugePanelView(isCompact: true)
                StatusBanner()
                MetricGridView(columns: 2)
                ModelUsagePanel()
                RecentRequestsPanel(limit: 5)
                TrendCardsView()
            }
            .padding(16)
        }
        .background(
            ZStack {
                palette.background
                DotGridBackground(color: palette.border.opacity(0.16), spacing: 18)
            }
        )
    }
}

struct FocusDashboardView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var systemColorScheme

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < 900
            ZStack {
                palette.background
                DotGridBackground(color: palette.border.opacity(0.16), spacing: 18)

                GaugePanelView(isCompact: isCompact, showsSummary: false)
                    .frame(maxWidth: isCompact ? .infinity : min(proxy.size.width * 0.72, 720))
                    .padding(isCompact ? 16 : 32)
            }
        }
    }
}

struct GaugePanelView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(DashboardStore.self) private var dashboard
    @Environment(\.colorScheme) private var systemColorScheme
    let isCompact: Bool
    var showsSummary = true

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 20 : 28) {
            VStack(alignment: .leading, spacing: 4) {
                Text("DeepSeek")
                    .font(.system(.headline, design: .monospaced).weight(.bold))
                    .foregroundStyle(palette.primary)
                Text(settings.language.text(.usageMonitor))
                    .font(.system(.caption2, design: .monospaced).weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(palette.muted)
                Rectangle()
                    .fill(palette.strongBorder)
                    .frame(width: 42, height: 1)
                    .padding(.top, 6)
            }

            Spacer(minLength: 0)

            BalanceGaugeView(size: isCompact ? 300 : 500)
                .frame(maxWidth: .infinity)

            Spacer(minLength: 0)

            if showsSummary, isCompact {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    MiniTrendView(title: settings.language.text(.todaySpend), points: dashboard.data.spendTrend, value: MonitorFormatters.cny(dashboard.data.todaySpend))
                    MiniTrendView(title: settings.language.text(.tokens), points: dashboard.data.tokensTrend, value: MonitorFormatters.tokens(dashboard.data.todayTokens))
                    MiniTrendView(title: settings.language.text(.todayRequests), points: dashboard.data.requestsTrend, value: "\(dashboard.data.todayRequests)")
                }
            } else if showsSummary {
                HStack(spacing: 10) {
                    MiniTrendView(title: settings.language.text(.todaySpend), points: dashboard.data.spendTrend, value: MonitorFormatters.cny(dashboard.data.todaySpend))
                    MiniTrendView(title: settings.language.text(.tokens), points: dashboard.data.tokensTrend, value: MonitorFormatters.tokens(dashboard.data.todayTokens))
                    MiniTrendView(title: settings.language.text(.todayRequests), points: dashboard.data.requestsTrend, value: "\(dashboard.data.todayRequests)")
                }
            }
        }
        .padding(isCompact ? 18 : 28)
        .frame(maxWidth: .infinity)
        .frame(minHeight: isCompact ? (showsSummary ? 520 : 430) : nil)
    }
}

struct BalanceGaugeView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(DashboardStore.self) private var dashboard
    @Environment(\.colorScheme) private var systemColorScheme
    let size: CGFloat

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    private var progress: Double {
        guard dashboard.data.maxBalance > 0 else { return 0 }
        return min(max(dashboard.data.balance / dashboard.data.maxBalance, 0), 1)
    }

    var body: some View {
        IndustrialBalanceDial(
            balance: dashboard.data.balance,
            maxBalance: dashboard.data.maxBalance,
            todaySpend: dashboard.data.todaySpend,
            totalSpend: dashboard.data.totalSpend,
            uptimeSeconds: dashboard.uptimeSeconds,
            progress: progress,
            language: settings.language,
            palette: palette,
            size: size
        )
        .frame(width: size, height: size)
        .accessibilityLabel(settings.language.text(.balanceRemaining))
        .accessibilityValue(MonitorFormatters.cny(dashboard.data.balance))
    }
}

private struct IndustrialBalanceDial: View {
    let balance: Double
    let maxBalance: Double
    let todaySpend: Double
    let totalSpend: Double
    let uptimeSeconds: Int
    let progress: Double
    let language: AppLanguage
    let palette: MonitorPalette
    let size: CGFloat

    private var scale: CGFloat { size / 560 }
    private var arcRadius: CGFloat { size * 0.43 }
    private var arcWidth: CGFloat { size * 0.05 }
    private var innerRadius: CGFloat { arcRadius - arcWidth * 0.5 - 4 * scale }
    private var markerAngle: Double { -90 + progress * 360 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(palette.gaugeBezelOuter, lineWidth: 12 * scale)
                .frame(width: size * 0.99, height: size * 0.99)
            Circle()
                .stroke(palette.gaugeBezel, lineWidth: 22 * scale)
                .frame(width: size * 0.95, height: size * 0.95)
            Circle()
                .stroke(palette.gaugeBezel2, lineWidth: 1)
                .frame(width: size * 0.89, height: size * 0.89)

            GaugeTicks(size: size, palette: palette)

            Circle()
                .stroke(palette.gaugeTrack, lineWidth: arcWidth)
                .frame(width: arcRadius * 2, height: arcRadius * 2)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    palette.gaugeArc,
                    style: StrokeStyle(lineWidth: arcWidth, lineCap: .butt, lineJoin: .miter)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: arcRadius * 2, height: arcRadius * 2)
                .shadow(color: palette.gaugeArc.opacity(0.18), radius: 6 * scale)
                .animation(.spring(response: 0.55, dampingFraction: 0.84), value: progress)

            GaugeSegments(size: size, palette: palette)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [palette.gaugeCenterMid, palette.gaugeCenter],
                        center: .center,
                        startRadius: 0,
                        endRadius: innerRadius
                    )
                )
                .frame(width: innerRadius * 2, height: innerRadius * 2)
                .overlay(Circle().stroke(palette.gaugeInnerRing, lineWidth: 1.4 * scale))
                .overlay(Circle().stroke(palette.border.opacity(0.35), lineWidth: 0.4).padding(22 * scale))
                .shadow(color: .black.opacity(palette.isDark ? 0.45 : 0.08), radius: 24 * scale, y: 12 * scale)

            GaugeMarker(balance: balance, angle: markerAngle, size: size, palette: palette)

            VStack(spacing: 0) {
                Text(Date().formatted(date: .abbreviated, time: .omitted).uppercased())
                    .font(.system(size: 10 * scale, weight: .medium, design: .monospaced))
                    .foregroundStyle(palette.secondary)
                    .padding(.bottom, 9 * scale)
                Text(Date().formatted(date: .omitted, time: .shortened).uppercased())
                    .font(.system(size: 24 * scale, weight: .light, design: .monospaced))
                    .foregroundStyle(palette.primary)
                    .padding(.bottom, 16 * scale)
                Text(language.text(.balanceRemaining))
                    .font(.system(size: 9.5 * scale, weight: .semibold, design: .monospaced))
                    .foregroundStyle(palette.muted)
                    .padding(.bottom, 8 * scale)
                Rectangle()
                    .fill(palette.gaugeInnerRing)
                    .frame(width: 100 * scale, height: 1)
                    .padding(.bottom, 10 * scale)

                DotMatrixText(
                    text: MonitorFormatters.cny(balance),
                    dotSize: max(2.7, size / 82),
                    dotGap: max(1, size / 230),
                    charGap: max(4, size / 92),
                    active: palette.dotMatrixActive,
                    inactive: palette.dotMatrixInactive
                )
                .shadow(color: palette.dotMatrixActive.opacity(palette.isDark ? 0.35 : 0.12), radius: 4 * scale)
                .padding(.bottom, 10 * scale)

                Text("CNY")
                    .font(.system(size: 10 * scale, weight: .medium, design: .monospaced))
                    .tracking(6 * scale)
                    .foregroundStyle(palette.muted)
                    .padding(.bottom, 8 * scale)
                Rectangle()
                    .fill(palette.gaugeInnerRing)
                    .frame(width: 100 * scale, height: 1)
                    .padding(.bottom, 9 * scale)

                HStack(spacing: 8 * scale) {
                    Text(language.text(.today))
                        .foregroundStyle(palette.muted)
                    Text(MonitorFormatters.cny(todaySpend))
                        .foregroundStyle(palette.primary)
                }
                .font(.system(size: 10 * scale, weight: .semibold, design: .monospaced))
                .padding(.bottom, 4 * scale)

                HStack(spacing: 8 * scale) {
                    Text(language.text(.total))
                        .foregroundStyle(palette.muted)
                    Text(MonitorFormatters.cny(totalSpend))
                        .foregroundStyle(palette.secondary)
                }
                .font(.system(size: 10 * scale, weight: .semibold, design: .monospaced))

                Text("MAX \(Int(maxBalance)) CNY")
                    .font(.system(size: 7.5 * scale, weight: .medium, design: .monospaced))
                    .foregroundStyle(palette.muted)
                    .padding(.top, 8 * scale)
            }
            .frame(width: innerRadius * 1.55)

            VStack {
                Spacer()
                HStack(spacing: 8) {
                    Text(language.text(.uptime))
                        .font(.system(size: 11 * scale, weight: .semibold, design: .monospaced))
                        .foregroundStyle(palette.muted)
                    Text(MonitorFormatters.relativeUptime(uptimeSeconds))
                        .font(.system(size: 14 * scale, weight: .bold, design: .monospaced))
                        .foregroundStyle(palette.secondary)
                }
                .offset(y: size * 0.065)
            }
        }
    }
}

private struct GaugeTicks: View {
    let size: CGFloat
    let palette: MonitorPalette

    var body: some View {
        ForEach(0..<120, id: \.self) { index in
            let isMajor = index.isMultiple(of: 10)
            let isMid = index.isMultiple(of: 5)
            Rectangle()
                .fill(isMajor ? palette.gaugeTickMajor : isMid ? palette.gaugeTickMid : palette.gaugeTickMinor)
                .frame(width: isMajor ? 1.4 : isMid ? 0.9 : 0.55, height: isMajor ? size * 0.028 : isMid ? size * 0.017 : size * 0.010)
                .offset(y: -size * 0.49)
                .rotationEffect(.degrees(Double(index) * 3))
        }
    }
}

private struct GaugeSegments: View {
    let size: CGFloat
    let palette: MonitorPalette

    var body: some View {
        ForEach(0..<72, id: \.self) { index in
            Rectangle()
                .fill(palette.gaugeCenter)
                .frame(width: 1.4, height: size * 0.055)
                .offset(y: -size * 0.43)
                .rotationEffect(.degrees(Double(index) * 5))
        }
    }
}

private struct GaugeMarker: View {
    let balance: Double
    let angle: Double
    let size: CGFloat
    let palette: MonitorPalette

    private var radians: Double { angle * .pi / 180 }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(palette.warning)
                .frame(width: 1.6, height: size * 0.035)
                .offset(y: -size * 0.515)
                .rotationEffect(.degrees(angle))
                .shadow(color: palette.warning.opacity(0.45), radius: 3)

            Text(balance.formatted(.number.precision(.fractionLength(0))))
                .font(.system(size: max(7, size * 0.017), weight: .bold, design: .monospaced))
                .foregroundStyle(palette.warning)
                .position(
                    x: size / 2 + cos(radians) * size * 0.535,
                    y: size / 2 + sin(radians) * size * 0.535
                )
        }
        .frame(width: size, height: size)
    }
}

private struct DotMatrixText: View {
    let text: String
    let dotSize: CGFloat
    let dotGap: CGFloat
    let charGap: CGFloat
    let active: Color
    let inactive: Color

    var body: some View {
        HStack(alignment: .top, spacing: charGap) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, character in
                DotMatrixCharacter(
                    pattern: DotMatrixCharacter.pattern(for: character),
                    dotSize: dotSize,
                    dotGap: dotGap,
                    active: active,
                    inactive: inactive
                )
            }
        }
    }
}

private struct DotMatrixCharacter: View {
    let pattern: [String]
    let dotSize: CGFloat
    let dotGap: CGFloat
    let active: Color
    let inactive: Color

    var body: some View {
        VStack(spacing: dotGap) {
            ForEach(Array(pattern.enumerated()), id: \.offset) { _, row in
                HStack(spacing: dotGap) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                        RoundedRectangle(cornerRadius: dotSize * 0.16)
                            .fill(cell == "1" ? active : inactive)
                            .frame(width: dotSize, height: dotSize)
                    }
                }
            }
        }
    }

    static func pattern(for character: Character) -> [String] {
        switch character {
        case "0": return ["01110", "10001", "10001", "10001", "10001", "10001", "01110"]
        case "1": return ["00100", "01100", "00100", "00100", "00100", "00100", "01110"]
        case "2": return ["11111", "00001", "00001", "11111", "10000", "10000", "11111"]
        case "3": return ["11111", "00001", "00001", "01111", "00001", "00001", "11111"]
        case "4": return ["10001", "10001", "10001", "11111", "00001", "00001", "00001"]
        case "5": return ["11111", "10000", "10000", "11111", "00001", "00001", "11111"]
        case "6": return ["11111", "10000", "10000", "11111", "10001", "10001", "11111"]
        case "7": return ["11111", "00001", "00001", "00001", "00001", "00001", "00001"]
        case "8": return ["11111", "10001", "10001", "11111", "10001", "10001", "11111"]
        case "9": return ["11111", "10001", "10001", "11111", "00001", "00001", "11111"]
        case ".": return ["0", "0", "0", "0", "0", "1", "1"]
        case "¥": return ["10001", "01010", "00100", "11111", "00100", "11111", "00100"]
        default: return ["00000", "00000", "00000", "00000", "00000", "00000", "00000"]
        }
    }
}

struct StatusBanner: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(DashboardStore.self) private var dashboard
    @Environment(\.colorScheme) private var systemColorScheme

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: dashboard.isLive ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(dashboard.isLive ? palette.accent : palette.warning)
            VStack(alignment: .leading, spacing: 2) {
                Text(dashboard.isLive ? settings.language.text(.live) : settings.language.text(.mockMode))
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(palette.primary)
                Text(dashboard.statusMessage ?? "")
                    .font(.caption)
                    .foregroundStyle(palette.secondary)
                if let error = dashboard.lastErrorMessage {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(palette.warning)
                        .lineLimit(2)
                }
            }
            Spacer()
            if dashboard.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(14)
        .industrialCard()
    }
}

struct MetricGridView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(DashboardStore.self) private var dashboard
    let columns: Int

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns), spacing: 12) {
            MetricCardView(title: settings.language.text(.todayRequests), value: "\(dashboard.data.todayRequests)", detail: settings.language.text(.autoRefresh), systemImage: "arrow.up.forward.circle")
            MetricCardView(title: settings.language.text(.todayTokens), value: MonitorFormatters.tokens(dashboard.data.todayTokens), detail: "PROMPT + COMP.", systemImage: "number")
            MetricCardView(title: settings.language.text(.todaySpend), value: MonitorFormatters.cny(dashboard.data.todaySpend), detail: "CNY", systemImage: "yensign.circle", accent: .red)
            MetricCardView(title: settings.language.text(.totalSpend), value: MonitorFormatters.cny(dashboard.data.totalSpend), detail: settings.language.text(.estimateNote), systemImage: "sum")
        }
    }
}

struct MetricCardView: View {
    enum Accent: Equatable {
        case neutral
        case red
    }

    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var systemColorScheme
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    var accent: Accent = .neutral

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(.caption2, design: .monospaced).weight(.semibold))
                    .foregroundStyle(palette.muted)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                Spacer()
                Image(systemName: systemImage)
                    .foregroundStyle(palette.secondary)
            }
            Text(value)
                .font(.system(size: 40, weight: .black, design: .monospaced))
                .foregroundStyle(accent == .red ? palette.warning : palette.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(palette.muted)
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
        .industrialCard()
        .overlay(alignment: .top) {
            Rectangle()
                .fill(accent == .red ? palette.warning : palette.strongBorder)
                .frame(height: 2)
                .padding(.horizontal, 1)
        }
    }
}

struct ModelUsagePanel: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(DashboardStore.self) private var dashboard
    @Environment(\.colorScheme) private var systemColorScheme

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PanelHeader(title: settings.language.text(.modelUsageToday), systemImage: "chart.bar.xaxis")
            ForEach(dashboard.data.models) { model in
                VStack(alignment: .leading, spacing: 10) {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            ModelBadge(model: model)
                            Text(model.name)
                                .font(.system(.caption, design: .monospaced).weight(.bold))
                                .foregroundStyle(palette.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Spacer()
                            UsageCell(label: settings.language.text(.todayRequests), value: "\(model.requests)")
                            UsageCell(label: "TOKENS", value: MonitorFormatters.tokens(model.totalTokens))
                            UsageCell(label: "COST", value: MonitorFormatters.cny(model.estimatedCost))
                            UsageCell(label: "SHARE", value: "\(model.percentage.formatted(.number.precision(.fractionLength(1))))%")
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                ModelBadge(model: model)
                                Text(model.name)
                                    .font(.system(.caption, design: .monospaced).weight(.bold))
                                    .foregroundStyle(palette.primary)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(model.percentage.formatted(.number.precision(.fractionLength(1))))%")
                                    .font(.system(.caption, design: .monospaced).weight(.bold))
                                    .foregroundStyle(palette.secondary)
                            }
                            HStack {
                                UsageCell(label: settings.language.text(.todayRequests), value: "\(model.requests)")
                                Spacer()
                                UsageCell(label: "TOKENS", value: MonitorFormatters.tokens(model.totalTokens))
                                Spacer()
                                UsageCell(label: "COST", value: MonitorFormatters.cny(model.estimatedCost))
                            }
                        }
                    }
                    SegmentedUsageBar(percentage: model.percentage)
                }
                .padding(.vertical, 6)
                if model.id != (dashboard.data.models.last?.id ?? "") {
                    Rectangle()
                        .fill(palette.border.opacity(0.55))
                        .frame(height: 1)
                }
            }
        }
        .panelChrome()
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct ModelBadge: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var systemColorScheme
    let model: ModelUsageData

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    var body: some View {
        Text(model.name.contains("pro") ? "PRO" : "FLASH")
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(model.name.contains("pro") ? palette.blue : palette.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(model.name.contains("pro") ? palette.blue : palette.strongBorder, lineWidth: 1)
            )
    }
}

private struct UsageCell: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var systemColorScheme
    let label: String
    let value: String

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundStyle(palette.muted)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(palette.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(minWidth: 44, alignment: .trailing)
    }
}

private struct SegmentedUsageBar: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var systemColorScheme
    let percentage: Double

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<28, id: \.self) { index in
                Rectangle()
                    .fill(Double(index + 1) <= percentage / 100 * 28 ? palette.primary.opacity(0.75) : palette.border.opacity(0.6))
                    .frame(height: 4)
            }
        }
    }
}

struct RecentRequestsPanel: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(DashboardStore.self) private var dashboard
    @Environment(\.colorScheme) private var systemColorScheme
    let limit: Int

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PanelHeader(title: settings.language.text(.recentRequests), systemImage: "clock.arrow.circlepath")
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    Text(settings.language.text(.today))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    Spacer(minLength: 8)
                    Text("MODEL")
                        .frame(width: 130, alignment: .leading)
                    Text("TOKENS")
                        .frame(width: 64, alignment: .trailing)
                    Text("COST")
                        .frame(width: 64, alignment: .trailing)
                    Text("STATUS")
                        .frame(width: 64, alignment: .trailing)
                }
                HStack(spacing: 8) {
                    Text("MODEL")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("TOKENS")
                        .frame(width: 54, alignment: .trailing)
                    Text("COST")
                        .frame(width: 54, alignment: .trailing)
                    Text("STATUS")
                        .frame(width: 48, alignment: .trailing)
                }
                EmptyView()
            }
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundStyle(palette.muted)
            .lineLimit(1)
            .padding(.bottom, 2)
            Rectangle()
                .fill(palette.border.opacity(0.55))
                .frame(height: 1)
            ForEach(dashboard.data.recentRequests.prefix(limit)) { request in
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        Text(MonitorFormatters.shortTime(request.timestamp))
                            .frame(width: 56, alignment: .leading)
                        RequestBadge(request: request)
                        Text(request.model)
                            .foregroundStyle(palette.primary)
                            .lineLimit(1)
                        Spacer()
                        Text(MonitorFormatters.tokens(request.totalTokens))
                            .frame(width: 64, alignment: .trailing)
                        Text(MonitorFormatters.cny(request.estimatedCost, digits: 4))
                            .frame(width: 64, alignment: .trailing)
                        RequestStatus(request: request)
                            .frame(width: 64, alignment: .trailing)
                    }

                    HStack(spacing: 10) {
                        RequestBadge(request: request)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(request.model)
                                .foregroundStyle(palette.primary)
                                .lineLimit(1)
                            Text("\(MonitorFormatters.shortTime(request.timestamp))  \(request.latencyMs)ms")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(palette.muted)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(MonitorFormatters.tokens(request.totalTokens))
                            Text(MonitorFormatters.cny(request.estimatedCost, digits: 4))
                                .foregroundStyle(request.status == .success ? palette.secondary : palette.warning)
                        }
                        RequestStatus(request: request)
                    }
                }
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(palette.secondary)
                .padding(.vertical, 6)
                if request.id != (dashboard.data.recentRequests.prefix(limit).last?.id ?? "") {
                    Rectangle()
                        .fill(palette.border.opacity(0.32))
                        .frame(height: 1)
                }
            }
        }
        .panelChrome()
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct RequestBadge: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var systemColorScheme
    let request: RequestRecord

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    var body: some View {
        Text(request.model.contains("pro") ? "PRO" : "FLASH")
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(request.model.contains("pro") ? palette.blue : palette.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(request.model.contains("pro") ? palette.blue : palette.border))
    }
}

private struct RequestStatus: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var systemColorScheme
    let request: RequestRecord

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(request.status == .success ? palette.accent : palette.warning)
                .frame(width: 5, height: 5)
            Text(request.status == .success ? "成功" : "错误")
        }
        .foregroundStyle(request.status == .success ? palette.accent : palette.warning)
    }
}

struct TrendCardsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(DashboardStore.self) private var dashboard

    var body: some View {
        HStack(spacing: 12) {
            MiniTrendView(title: settings.language.text(.todaySpend), points: dashboard.data.spendTrend, value: MonitorFormatters.cny(dashboard.data.todaySpend))
            MiniTrendView(title: settings.language.text(.todayTokens), points: dashboard.data.tokensTrend, value: MonitorFormatters.tokens(dashboard.data.todayTokens))
            MiniTrendView(title: settings.language.text(.todayRequests), points: dashboard.data.requestsTrend, value: "\(dashboard.data.todayRequests)")
        }
    }
}

struct MiniTrendView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var systemColorScheme
    let title: String
    let points: [TrendPoint]
    let value: String

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    Text(title)
                        .font(.system(.caption2, design: .monospaced).weight(.semibold))
                        .foregroundStyle(palette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Spacer(minLength: 6)
                    Text(value)
                        .font(.system(.caption, design: .monospaced).weight(.bold))
                        .foregroundStyle(palette.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.caption2, design: .monospaced).weight(.semibold))
                        .foregroundStyle(palette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Text(value)
                        .font(.system(.caption, design: .monospaced).weight(.bold))
                        .foregroundStyle(palette.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            SparklineView(points: points)
                .frame(height: 38)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .industrialCard()
    }
}

struct SparklineView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var systemColorScheme
    let points: [TrendPoint]

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    var body: some View {
        GeometryReader { proxy in
            let values = points.map(\.value)
            let minValue = values.min() ?? 0
            let maxValue = values.max() ?? 1
            let span = max(maxValue - minValue, 0.0001)

            Path { path in
                for (index, point) in points.enumerated() {
                    let x = proxy.size.width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                    let normalized = (point.value - minValue) / span
                    let y = proxy.size.height - (proxy.size.height * CGFloat(normalized))
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(palette.primary, style: StrokeStyle(lineWidth: 1.6, lineCap: .square, lineJoin: .miter))

            if let last = points.last, points.count > 1 {
                let values = points.map(\.value)
                let minValue = values.min() ?? 0
                let maxValue = values.max() ?? 1
                let span = max(maxValue - minValue, 0.0001)
                let normalized = (last.value - minValue) / span
                let y = proxy.size.height - (proxy.size.height * CGFloat(normalized))
                Rectangle()
                    .fill(palette.primary)
                    .frame(width: 5, height: 5)
                    .position(x: proxy.size.width, y: y)
            }
        }
    }
}

struct PanelHeader: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var systemColorScheme
    let title: String
    let systemImage: String

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(.system(.caption, design: .monospaced).weight(.bold))
                .foregroundStyle(palette.primary)
            Spacer()
        }
    }
}

private struct PanelChrome: ViewModifier {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var systemColorScheme

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                ZStack {
                    palette.card
                    DotGridBackground(color: palette.border.opacity(0.28), spacing: 14)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(palette.border))
            .shadow(color: .black.opacity(palette.isDark ? 0.40 : 0.08), radius: 18, y: 8)
    }
}

private struct IndustrialCard: ViewModifier {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var systemColorScheme

    private var palette: MonitorPalette {
        MonitorPalette.palette(for: settings.appTheme.resolved(using: systemColorScheme))
    }

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    palette.card
                    DotGridBackground(color: palette.border.opacity(0.28), spacing: 14)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(palette.border))
            .shadow(color: .black.opacity(palette.isDark ? 0.34 : 0.08), radius: 16, y: 6)
    }
}

struct DotGridBackground: View {
    let color: Color
    var spacing: CGFloat

    var body: some View {
        Canvas { context, size in
            for x in stride(from: CGFloat(0), through: size.width, by: spacing) {
                for y in stride(from: CGFloat(0), through: size.height, by: spacing) {
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                        with: .color(color)
                    )
                }
            }
        }
    }
}

private extension View {
    func panelChrome() -> some View {
        modifier(PanelChrome())
    }

    func industrialCard() -> some View {
        modifier(IndustrialCard())
    }
}
