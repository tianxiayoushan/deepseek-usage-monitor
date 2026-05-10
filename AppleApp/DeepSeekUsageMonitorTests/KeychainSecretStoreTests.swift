import XCTest

final class KeychainSecretStoreTests: XCTestCase {
    private var store: KeychainSecretStore!

    override func setUpWithError() throws {
        try super.setUpWithError()
        store = KeychainSecretStore(
            service: "com.local.DeepSeekUsageMonitor.tests.\(UUID().uuidString)",
            account: "api-key"
        )
        try store.clearAPIKey()
    }

    override func tearDownWithError() throws {
        try store.clearAPIKey()
        store = nil
        try super.tearDownWithError()
    }

    func testSaveOverwriteReadAndClearAPIKey() throws {
        XCTAssertNil(try store.readAPIKey())

        try store.saveAPIKey("sk-first")
        XCTAssertEqual(try store.readAPIKey(), "sk-first")

        try store.saveAPIKey("sk-second")
        XCTAssertEqual(try store.readAPIKey(), "sk-second")

        try store.clearAPIKey()
        XCTAssertNil(try store.readAPIKey())
    }
}
