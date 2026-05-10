import XCTest

final class SettingsStoreTests: XCTestCase {
    func testGaugeMaxValidation() {
        XCTAssertEqual(SettingsStore.validateGaugeMax(50), 100)
        XCTAssertEqual(SettingsStore.validateGaugeMax(125), 100)
        XCTAssertEqual(SettingsStore.validateGaugeMax(180), 200)
        XCTAssertEqual(SettingsStore.validateGaugeMax(1200), 100)
    }

    func testDisplayMaxBalanceExpandsAboveConfiguredRange() {
        let defaults = UserDefaults(suiteName: "DeepSeekUsageMonitorTests.\(UUID().uuidString)")!
        let settings = SettingsStore(defaults: defaults)
        settings.gaugeMaxAmount = 100

        XCTAssertEqual(settings.displayMaxBalance(for: 83.42), 100)
        XCTAssertEqual(settings.displayMaxBalance(for: 150), 180)
    }
}
