import Foundation

struct SharedDashboardSnapshot: Codable, Equatable {
    var balance: Double
    var maxBalance: Double
    var todaySpend: Double
    var todayTokens: Int
    var todayRequests: Int
    var totalSpend: Double
    var lastUpdatedAt: Date
    var isLive: Bool
    var refreshIntervalSeconds: Int
    var statusMessage: String?

    static let placeholder = SharedDashboardSnapshot(
        balance: 83.42,
        maxBalance: 100,
        todaySpend: 1.27,
        todayTokens: 1_280_000,
        todayRequests: 142,
        totalSpend: 16.58,
        lastUpdatedAt: Date(timeIntervalSince1970: 0),
        isLive: false,
        refreshIntervalSeconds: 300,
        statusMessage: "安全摘要"
    )
}

struct SharedDashboardSnapshotStore {
    static let appGroupID = "group.com.local.DeepSeekUsageMonitor"

    private enum Keys {
        static let latestSnapshot = "ds-native-latest-dashboard-snapshot"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults? = UserDefaults(suiteName: Self.appGroupID)) {
        self.defaults = defaults ?? .standard
    }

    func save(_ snapshot: SharedDashboardSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }
        defaults.set(data, forKey: Keys.latestSnapshot)
    }

    func load() -> SharedDashboardSnapshot? {
        guard let data = defaults.data(forKey: Keys.latestSnapshot) else {
            return nil
        }
        return try? JSONDecoder().decode(SharedDashboardSnapshot.self, from: data)
    }

    func clear() {
        defaults.removeObject(forKey: Keys.latestSnapshot)
    }
}
