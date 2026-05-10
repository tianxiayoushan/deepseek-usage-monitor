import Foundation

#if os(iOS)
import BackgroundTasks
import WidgetKit

enum BackgroundRefreshScheduler {
    static let identifier = "com.local.DeepSeekUsageMonitor.refresh"

    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handle(task)
        }
    }

    static func schedule(refreshIntervalSeconds: Int = 15 * 60) {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        let earliestSeconds = max(refreshIntervalSeconds, 15 * 60)
        request.earliestBeginDate = Date(timeIntervalSinceNow: TimeInterval(earliestSeconds))
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handle(_ task: BGAppRefreshTask) {
        let work = Task<Bool, Never> {
            await refreshSnapshot()
        }

        task.expirationHandler = {
            work.cancel()
        }

        Task {
            let success = await work.value
            schedule(refreshIntervalSeconds: SettingsStore().refreshInterval.seconds)
            task.setTaskCompleted(success: success)
        }
    }

    private static func refreshSnapshot() async -> Bool {
        let secretStore = KeychainSecretStore()
        guard let apiKey = try? secretStore.readAPIKey()?.trimmingCharacters(in: .whitespacesAndNewlines),
              !apiKey.isEmpty else {
            return false
        }

        do {
            let settings = SettingsStore()
            let balance = try await DeepSeekBalanceClient().fetchBalance(apiKey: apiKey)
            let snapshotStore = SharedDashboardSnapshotStore()
            var snapshot = snapshotStore.load() ?? .placeholder
            snapshot.balance = balance.totalBalance
            snapshot.maxBalance = settings.displayMaxBalance(for: balance.totalBalance)
            if let initialTotalCredit = settings.initialTotalCredit {
                snapshot.totalSpend = max(initialTotalCredit - balance.totalBalance, 0)
            }
            snapshot.lastUpdatedAt = Date()
            snapshot.isLive = true
            snapshot.refreshIntervalSeconds = settings.refreshInterval.seconds
            snapshot.statusMessage = "后台已刷新"
            snapshotStore.save(snapshot)
            WidgetCenter.shared.reloadTimelines(ofKind: "DeepSeekUsageMonitorWidget")
            return true
        } catch {
            return false
        }
    }
}
#endif
