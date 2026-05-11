import Foundation
import Observation
#if os(iOS) && canImport(WidgetKit)
import WidgetKit
#endif

@MainActor
@Observable
final class DashboardStore {
    private let settings: SettingsStore
    private let secretStore: SecretStoring
    private let balanceClient: BalanceFetching
    private let snapshotStore: SharedDashboardSnapshotStore
    private var refreshTask: Task<Void, Never>?

    var data: DashboardData
    var isLoading = false
    var isLive = false
    var apiKeyConfigured = false
    var statusMessage: String?
    var lastErrorMessage: String?
    var uptimeSeconds = 0

    init(
        settings: SettingsStore,
        secretStore: SecretStoring = KeychainSecretStore(),
        balanceClient: BalanceFetching = DeepSeekBalanceClient(),
        snapshotStore: SharedDashboardSnapshotStore = SharedDashboardSnapshotStore()
    ) {
        self.settings = settings
        self.secretStore = secretStore
        self.balanceClient = balanceClient
        self.snapshotStore = snapshotStore
        data = DashboardData.mock()
        apiKeyConfigured = (try? secretStore.readAPIKey())?.isEmpty == false
        persistSnapshot()
    }

    func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            await self.refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self.settings.refreshInterval.seconds))
                if Task.isCancelled { return }
                await self.refresh()
            }
        }
    }

    func restartAutoRefresh() {
        startAutoRefresh()
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func tickUptime() {
        uptimeSeconds += 1
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        guard let apiKey = try? secretStore.readAPIKey()?.trimmingCharacters(in: .whitespacesAndNewlines),
              !apiKey.isEmpty else {
            apiKeyConfigured = false
            applyMock(message: settings.language.text(.apiKeyMissing), error: nil)
            return
        }

        apiKeyConfigured = true
        do {
            let balance = try await balanceClient.fetchBalance(apiKey: apiKey)
            apply(balance: balance)
        } catch {
            applyMock(message: settings.language.text(.balanceLoadFailed), error: error.localizedDescription)
        }
    }

    func saveSettings(apiKey: String?, initialTotalCredit: Double?) async throws {
        if let trimmed = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty {
            try secretStore.saveAPIKey(trimmed)
            apiKeyConfigured = true
        }
        settings.initialTotalCredit = initialTotalCredit
        await refresh()
    }

    func clearAPIKey() throws {
        try secretStore.clearAPIKey()
        apiKeyConfigured = false
        applyMock(message: settings.language.text(.apiKeyMissing), error: nil)
    }

    func estimatedTotalSpend(balance: Double) -> Double? {
        guard let initial = settings.initialTotalCredit else {
            return nil
        }
        return max(initial - balance, 0)
    }

    private func apply(balance: BalanceSnapshot) {
        let totalSpend = estimatedTotalSpend(balance: balance.totalBalance) ?? 0
        let next = DashboardData.liveBalanceOnly(
            balance: balance.totalBalance,
            maxBalance: settings.displayMaxBalance(for: balance.totalBalance),
            totalSpend: totalSpend
        )
        data = next
        isLive = true
        statusMessage = "\(settings.language.text(.liveBalanceLoaded)) \(settings.language.text(.liveUsageUnavailable)) \(settings.language.text(.autoRefresh)) \(settings.refreshInterval.seconds)s"
        lastErrorMessage = nil
        persistSnapshot()
    }

    private func applyMock(message: String, error: String?) {
        var next = DashboardData.mock()
        next.maxBalance = settings.displayMaxBalance(for: next.balance)
        next.lastUpdatedAt = Date()
        data = next
        isLive = false
        statusMessage = message
        lastErrorMessage = error
        persistSnapshot()
    }

    private func persistSnapshot() {
        let snapshot = SharedDashboardSnapshot(
            balance: data.balance,
            maxBalance: data.maxBalance,
            todaySpend: data.todaySpend,
            todayTokens: data.todayTokens,
            todayRequests: data.todayRequests,
            totalSpend: data.totalSpend,
            lastUpdatedAt: data.lastUpdatedAt,
            isLive: isLive,
            refreshIntervalSeconds: settings.refreshInterval.seconds,
            statusMessage: statusMessage
        )
        snapshotStore.save(snapshot)
        #if os(iOS) && canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "DeepSeekUsageMonitorWidget")
        BackgroundRefreshScheduler.schedule(refreshIntervalSeconds: settings.refreshInterval.seconds)
        #endif
    }
}
