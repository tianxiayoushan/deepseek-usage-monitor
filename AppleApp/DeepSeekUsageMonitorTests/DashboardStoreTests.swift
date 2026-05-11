import Foundation
import XCTest

@MainActor
final class DashboardStoreTests: XCTestCase {
    func testRefreshWithoutAPIKeyUsesMockData() async {
        let settings = SettingsStore(defaults: isolatedDefaults())
        let store = DashboardStore(
            settings: settings,
            secretStore: InMemorySecretStore(apiKey: nil),
            balanceClient: StubBalanceClient(result: .success(.sample))
        )

        await store.refresh()

        XCTAssertFalse(store.apiKeyConfigured)
        XCTAssertFalse(store.isLive)
        XCTAssertEqual(store.data.balance, DashboardData.mock().balance, accuracy: 0.001)
        XCTAssertEqual(store.statusMessage, settings.language.text(.apiKeyMissing))
    }

    func testRefreshWithLiveBalanceOverridesBalanceAndEstimatedSpend() async {
        let settings = SettingsStore(defaults: isolatedDefaults())
        settings.initialTotalCredit = 100
        let store = DashboardStore(
            settings: settings,
            secretStore: InMemorySecretStore(apiKey: "sk-test"),
            balanceClient: StubBalanceClient(result: .success(.sample))
        )

        await store.refresh()

        XCTAssertTrue(store.apiKeyConfigured)
        XCTAssertTrue(store.isLive)
        XCTAssertEqual(store.data.balance, 42.5, accuracy: 0.001)
        XCTAssertEqual(store.data.totalSpend, 57.5, accuracy: 0.001)
        XCTAssertEqual(store.data.maxBalance, 100, accuracy: 0.001)
        XCTAssertEqual(store.data.todayRequests, 0)
        XCTAssertEqual(store.data.todayTokens, 0)
        XCTAssertEqual(store.data.todaySpend, 0, accuracy: 0.001)
        XCTAssertTrue(store.data.models.isEmpty)
        XCTAssertTrue(store.data.recentRequests.isEmpty)
        XCTAssertTrue(store.data.spendTrend.isEmpty)
    }

    func testRefreshFailureFallsBackToMockWithError() async {
        let settings = SettingsStore(defaults: isolatedDefaults())
        let store = DashboardStore(
            settings: settings,
            secretStore: InMemorySecretStore(apiKey: "sk-test"),
            balanceClient: StubBalanceClient(result: .failure(BalanceClientError.httpStatus(401)))
        )

        await store.refresh()

        XCTAssertFalse(store.isLive)
        XCTAssertEqual(store.data.balance, DashboardData.mock().balance, accuracy: 0.001)
        XCTAssertEqual(store.lastErrorMessage, "DeepSeek returned HTTP 401.")
    }

    private func isolatedDefaults() -> UserDefaults {
        let suite = "DeepSeekUsageMonitorTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}

private final class InMemorySecretStore: SecretStoring {
    var apiKey: String?

    init(apiKey: String?) {
        self.apiKey = apiKey
    }

    func readAPIKey() throws -> String? {
        apiKey
    }

    func saveAPIKey(_ apiKey: String) throws {
        self.apiKey = apiKey
    }

    func clearAPIKey() throws {
        apiKey = nil
    }
}

private struct StubBalanceClient: BalanceFetching {
    var result: Result<BalanceSnapshot, Error>

    func fetchBalance(apiKey: String) async throws -> BalanceSnapshot {
        try result.get()
    }
}

private extension BalanceSnapshot {
    static let sample = BalanceSnapshot(
        available: true,
        currency: "CNY",
        totalBalance: 42.5,
        grantedBalance: 2.5,
        toppedUpBalance: 40
    )
}
