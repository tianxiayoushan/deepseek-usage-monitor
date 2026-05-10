import WidgetKit
import SwiftUI

private struct UsageEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedDashboardSnapshot
}

private struct UsageProvider: TimelineProvider {
    private let snapshotStore = SharedDashboardSnapshotStore()
    private let secretStore = KeychainSecretStore()
    private let balanceClient = DeepSeekBalanceClient()
    private let minimumWidgetRefreshSeconds = 15 * 60

    func placeholder(in context: Context) -> UsageEntry {
        UsageEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (UsageEntry) -> Void) {
        let snapshot = snapshotStore.load() ?? .placeholder
        completion(UsageEntry(date: snapshot.lastUpdatedAt, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> Void) {
        Task {
            let snapshot = await refreshedSnapshot()
            let now = Date()
            let entryDate = snapshot.lastUpdatedAt > Date(timeIntervalSince1970: 1) ? snapshot.lastUpdatedAt : now
            let nextRefreshSeconds = max(snapshot.refreshIntervalSeconds, minimumWidgetRefreshSeconds)
            let nextRefresh = now.addingTimeInterval(TimeInterval(nextRefreshSeconds))
            completion(Timeline(entries: [UsageEntry(date: entryDate, snapshot: snapshot)], policy: .after(nextRefresh)))
        }
    }

    private func refreshedSnapshot() async -> SharedDashboardSnapshot {
        let existing = snapshotStore.load() ?? .placeholder
        guard let apiKey = try? secretStore.readAPIKey()?.trimmingCharacters(in: .whitespacesAndNewlines),
              !apiKey.isEmpty else {
            return existing
        }

        do {
            let balance = try await balanceClient.fetchBalance(apiKey: apiKey)
            var snapshot = existing
            snapshot.balance = balance.totalBalance
            snapshot.maxBalance = max(existing.maxBalance, roundedMaxBalance(for: balance.totalBalance))
            snapshot.lastUpdatedAt = Date()
            snapshot.isLive = true
            snapshot.statusMessage = "Widget 已刷新"
            snapshotStore.save(snapshot)
            return snapshot
        } catch {
            var snapshot = existing
            snapshot.isLive = false
            snapshot.statusMessage = "Widget 刷新失败"
            snapshotStore.save(snapshot)
            return snapshot
        }
    }

    private func roundedMaxBalance(for balance: Double) -> Double {
        guard balance > 100 else { return 100 }
        return ceil((balance * 1.2) / 10) * 10
    }
}

struct DeepSeekUsageMonitorWidget: Widget {
    let kind = "DeepSeekUsageMonitorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UsageProvider()) { entry in
            UsageWidgetView(entry: entry)
        }
        .configurationDisplayName("DeepSeek Monitor")
        .description("View DeepSeek balance and daily usage at a glance.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}

private struct UsageWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: UsageEntry

    private var palette: WidgetPalette {
        WidgetPalette(scheme: .dark)
    }

    var body: some View {
        ZStack {
            palette.background
            WidgetDotGrid(color: palette.grid)

            switch family {
            case .systemSmall:
                SmallWidget(snapshot: entry.snapshot, palette: palette)
            case .systemLarge:
                LargeWidget(snapshot: entry.snapshot, date: entry.date, palette: palette)
            default:
                MediumWidget(snapshot: entry.snapshot, date: entry.date, palette: palette)
            }
        }
        .containerBackground(for: .widget) {
            palette.background
        }
        .widgetAccentable(false)
    }
}

private struct SmallWidget: View {
    let snapshot: SharedDashboardSnapshot
    let palette: WidgetPalette

    var body: some View {
        GeometryReader { proxy in
            let side = max(104, min(proxy.size.width, proxy.size.height) - 18)

            ZStack {
                MiniGauge(snapshot: snapshot, palette: palette, size: side)

                VStack {
                    HStack(alignment: .center, spacing: 6) {
                        Text("DEEPSEEK")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .tracking(1.4)
                            .foregroundStyle(palette.text)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Circle()
                            .fill(snapshot.isLive ? palette.green : palette.red)
                            .frame(width: 6, height: 6)
                    }

                    Spacer(minLength: 0)

                    HStack(alignment: .firstTextBaseline) {
                        Text("SPEND")
                            .font(.system(size: 8, weight: .semibold, design: .monospaced))
                            .foregroundStyle(palette.label)
                        Spacer(minLength: 4)
                        Text(formatCNY(snapshot.todaySpend))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(palette.red)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                }
                .padding(10)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

private struct MediumWidget: View {
    let snapshot: SharedDashboardSnapshot
    let date: Date
    let palette: WidgetPalette

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                WidgetHeader(palette: palette, isLive: snapshot.isLive, message: snapshot.statusMessage)
                Spacer(minLength: 0)
                Text("剩余额度")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(palette.label)
                Text(formatCNY(snapshot.balance))
                    .font(.system(size: 32, weight: .black, design: .monospaced))
                    .foregroundStyle(palette.text)
                    .minimumScaleFactor(0.75)
                HStack(spacing: 12) {
                    WidgetMetric(label: "请求", value: "\(snapshot.todayRequests)", palette: palette)
                    WidgetMetric(label: "Token", value: formatTokens(snapshot.todayTokens), palette: palette)
                    WidgetMetric(label: "消费", value: formatCNY(snapshot.todaySpend), palette: palette, isRed: true)
                }
            }
            MiniGauge(snapshot: snapshot, palette: palette, size: 118)
        }
        .padding(16)
    }
}

private struct LargeWidget: View {
    let snapshot: SharedDashboardSnapshot
    let date: Date
    let palette: WidgetPalette

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                WidgetHeader(palette: palette, isLive: snapshot.isLive, message: snapshot.statusMessage)
                Spacer()
                Text(date.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(palette.muted)
            }

            MiniGauge(snapshot: snapshot, palette: palette, size: 184)

            HStack(spacing: 8) {
                WidgetMetricCard(label: "今日请求", value: "\(snapshot.todayRequests)", palette: palette)
                WidgetMetricCard(label: "今日 Token", value: formatTokens(snapshot.todayTokens), palette: palette)
            }
            HStack(spacing: 8) {
                WidgetMetricCard(label: "今日消费", value: formatCNY(snapshot.todaySpend), palette: palette, isRed: true)
                WidgetMetricCard(label: "累计消费", value: formatCNY(snapshot.totalSpend), palette: palette)
            }
        }
        .padding(16)
    }
}

private struct WidgetHeader: View {
    let palette: WidgetPalette
    let isLive: Bool
    var message: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("DEEPSEEK")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(2.6)
                .foregroundStyle(palette.text)
            HStack(spacing: 6) {
                Circle()
                    .fill(isLive ? palette.green : palette.red)
                    .frame(width: 5, height: 5)
                Text(isLive ? "在线" : "安全摘要")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(palette.muted)
            }
            if let message, !message.isEmpty {
                Text(message)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(palette.muted)
                    .lineLimit(1)
            }
        }
    }
}

private struct MiniGauge: View {
    let snapshot: SharedDashboardSnapshot
    let palette: WidgetPalette
    let size: CGFloat

    private var progress: Double {
        min(max(snapshot.balance / max(snapshot.maxBalance, 1), 0), 1)
    }

    var body: some View {
        ZStack {
            ForEach(0..<72, id: \.self) { index in
                Rectangle()
                    .fill(Double(index) / 72.0 <= progress ? palette.arc : palette.track)
                    .frame(width: size * 0.016, height: size * 0.13)
                    .offset(y: -size * 0.405)
                    .rotationEffect(.degrees(Double(index) * 5))
            }

            Circle()
                .stroke(palette.bezel, lineWidth: size * 0.06)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [palette.faceTop, palette.face],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.36
                    )
                )
                .frame(width: size * 0.66, height: size * 0.66)
                .overlay(Circle().stroke(palette.innerRing, lineWidth: 1))

            VStack(spacing: 4) {
                Text("CNY")
                    .font(.system(size: size * 0.055, weight: .semibold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(palette.label)
                Text(formatCNY(snapshot.balance))
                    .font(.system(size: size * 0.13, weight: .black, design: .monospaced))
                    .minimumScaleFactor(0.65)
                    .foregroundStyle(palette.text)
                Text("MAX \(Int(snapshot.maxBalance))")
                    .font(.system(size: size * 0.045, weight: .medium, design: .monospaced))
                    .foregroundStyle(palette.muted)
            }
            .frame(width: size * 0.58)
        }
        .frame(width: size, height: size)
    }
}

private struct WidgetMetric: View {
    let label: String
    let value: String
    let palette: WidgetPalette
    var isRed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundStyle(palette.label)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(isRed ? palette.red : palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }
}

private struct WidgetMetricCard: View {
    let label: String
    let value: String
    let palette: WidgetPalette
    var isRed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(palette.label)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundStyle(isRed ? palette.red : palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(palette.border))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct WidgetDotGrid: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 14
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

private struct WidgetPalette {
    let background: Color
    let card: Color
    let text: Color
    let label: Color
    let muted: Color
    let border: Color
    let grid: Color
    let red: Color
    let green: Color
    let arc: Color
    let track: Color
    let bezel: Color
    let face: Color
    let faceTop: Color
    let innerRing: Color

    init(scheme: ColorScheme) {
        if scheme == .dark {
            background = Color(red: 0.02, green: 0.02, blue: 0.02)
            card = Color(red: 0.055, green: 0.055, blue: 0.055)
            text = Color(red: 0.96, green: 0.96, blue: 0.93)
            label = Color(red: 0.70, green: 0.70, blue: 0.66)
            muted = Color(red: 0.55, green: 0.55, blue: 0.51)
            border = Color.white.opacity(0.16)
            grid = Color.white.opacity(0.07)
            red = Color(red: 1.00, green: 0.23, blue: 0.19)
            green = Color(red: 0.00, green: 0.82, blue: 0.52)
            arc = text
            track = Color(red: 0.10, green: 0.10, blue: 0.10)
            bezel = Color(red: 0.13, green: 0.13, blue: 0.13)
            face = Color(red: 0.03, green: 0.03, blue: 0.03)
            faceTop = Color(red: 0.07, green: 0.07, blue: 0.07)
            innerRing = Color.white.opacity(0.11)
        } else {
            background = Color(red: 0.96, green: 0.95, blue: 0.92)
            card = Color.white.opacity(0.92)
            text = Color(red: 0.07, green: 0.07, blue: 0.07)
            label = Color(red: 0.36, green: 0.36, blue: 0.33)
            muted = Color(red: 0.44, green: 0.44, blue: 0.40)
            border = Color.black.opacity(0.15)
            grid = Color.black.opacity(0.055)
            red = Color(red: 0.85, green: 0.19, blue: 0.15)
            green = Color(red: 0.00, green: 0.56, blue: 0.35)
            arc = text
            track = Color(red: 0.88, green: 0.87, blue: 0.84)
            bezel = Color(red: 0.72, green: 0.72, blue: 0.69)
            face = Color(red: 0.95, green: 0.94, blue: 0.91)
            faceTop = Color.white
            innerRing = Color.black.opacity(0.12)
        }
    }
}

private func formatCNY(_ value: Double) -> String {
    "¥" + value.formatted(.number.precision(.fractionLength(2)))
}

private func formatTokens(_ value: Int) -> String {
    if value >= 1_000_000 {
        return (Double(value) / 1_000_000).formatted(.number.precision(.fractionLength(2))) + "M"
    }
    if value >= 1_000 {
        return (Double(value) / 1_000).formatted(.number.precision(.fractionLength(0))) + "K"
    }
    return "\(value)"
}
