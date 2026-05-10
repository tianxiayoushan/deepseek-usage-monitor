import Foundation

protocol BalanceFetching {
    func fetchBalance(apiKey: String) async throws -> BalanceSnapshot
}

enum BalanceClientError: LocalizedError, Equatable {
    case invalidResponse
    case httpStatus(Int)
    case missingCNYBalance
    case unavailable(String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "DeepSeek returned an invalid response."
        case .httpStatus(let status):
            return "DeepSeek returned HTTP \(status)."
        case .missingCNYBalance:
            return "DeepSeek response did not include a CNY balance."
        case .unavailable(let reason):
            return reason ?? "DeepSeek balance is not available."
        }
    }
}

struct DeepSeekBalanceClient: BalanceFetching {
    private let endpoint = URL(string: "https://api.deepseek.com/user/balance")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchBalance(apiKey: String) async throws -> BalanceSnapshot {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BalanceClientError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw BalanceClientError.httpStatus(httpResponse.statusCode)
        }
        return try Self.decodeSnapshot(from: data)
    }

    static func decodeSnapshot(from data: Data) throws -> BalanceSnapshot {
        let response = try JSONDecoder().decode(DeepSeekBalanceResponse.self, from: data)
        guard response.isAvailable ?? true else {
            throw BalanceClientError.unavailable(nil)
        }
        guard let cny = response.balanceInfos.first(where: { $0.currency == "CNY" }) else {
            throw BalanceClientError.missingCNYBalance
        }
        guard let total = cny.totalBalance else {
            throw BalanceClientError.invalidResponse
        }
        return BalanceSnapshot(
            available: response.isAvailable ?? true,
            currency: cny.currency,
            totalBalance: total,
            grantedBalance: cny.grantedBalance ?? 0,
            toppedUpBalance: cny.toppedUpBalance ?? 0
        )
    }
}

private struct DeepSeekBalanceResponse: Decodable {
    var isAvailable: Bool?
    var balanceInfos: [DeepSeekBalanceInfo]

    enum CodingKeys: String, CodingKey {
        case isAvailable = "is_available"
        case balanceInfos = "balance_infos"
    }
}

private struct DeepSeekBalanceInfo: Decodable {
    var currency: String
    var totalBalance: Double?
    var grantedBalance: Double?
    var toppedUpBalance: Double?

    enum CodingKeys: String, CodingKey {
        case currency
        case totalBalance = "total_balance"
        case grantedBalance = "granted_balance"
        case toppedUpBalance = "topped_up_balance"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currency = try container.decode(String.self, forKey: .currency)
        totalBalance = container.decodeLossyDouble(forKey: .totalBalance)
        grantedBalance = container.decodeLossyDouble(forKey: .grantedBalance)
        toppedUpBalance = container.decodeLossyDouble(forKey: .toppedUpBalance)
    }
}

private extension KeyedDecodingContainer {
    func decodeLossyDouble(forKey key: Key) -> Double? {
        if let value = try? decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? decode(String.self, forKey: key) {
            return Double(value)
        }
        return nil
    }
}
