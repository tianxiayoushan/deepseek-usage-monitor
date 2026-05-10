import Foundation
import XCTest

final class DeepSeekBalanceClientTests: XCTestCase {
    func testDecodeCNYBalanceWithStringAmounts() throws {
        let json = """
        {
          "is_available": true,
          "balance_infos": [
            {
              "currency": "CNY",
              "total_balance": "83.42",
              "granted_balance": "10.00",
              "topped_up_balance": "73.42"
            }
          ]
        }
        """

        let snapshot = try DeepSeekBalanceClient.decodeSnapshot(from: Data(json.utf8))

        XCTAssertEqual(snapshot.currency, "CNY")
        XCTAssertEqual(snapshot.totalBalance, 83.42, accuracy: 0.001)
        XCTAssertEqual(snapshot.grantedBalance, 10.00, accuracy: 0.001)
        XCTAssertEqual(snapshot.toppedUpBalance, 73.42, accuracy: 0.001)
    }

    func testDecodeThrowsWhenCNYBalanceIsMissing() {
        let json = """
        {
          "is_available": true,
          "balance_infos": [
            { "currency": "USD", "total_balance": "5.00" }
          ]
        }
        """

        XCTAssertThrowsError(try DeepSeekBalanceClient.decodeSnapshot(from: Data(json.utf8))) { error in
            XCTAssertEqual(error as? BalanceClientError, .missingCNYBalance)
        }
    }

    func testHTTPStatusErrorDescriptionIsUseful() {
        let error = BalanceClientError.httpStatus(401)
        XCTAssertEqual(error.errorDescription, "DeepSeek returned HTTP 401.")
    }
}
