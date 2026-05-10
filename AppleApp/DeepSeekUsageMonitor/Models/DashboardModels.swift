import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case zh
    case en

    var id: String { rawValue }
}

enum AppTheme: String, CaseIterable, Codable, Identifiable {
    case dark
    case light
    case system

    var id: String { rawValue }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }

    func resolved(using systemScheme: ColorScheme) -> ColorScheme {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .system: return systemScheme
        }
    }
}

enum RefreshInterval: Int, CaseIterable, Codable, Identifiable {
    case five = 5
    case ten = 10
    case thirty = 30

    var id: Int { rawValue }
    var seconds: Int { rawValue }
}

struct ModelUsageData: Identifiable, Codable, Equatable {
    var id: String { name }
    var name: String
    var requests: Int
    var promptTokens: Int
    var completionTokens: Int
    var totalTokens: Int
    var estimatedCost: Double
    var percentage: Double
}

struct RequestRecord: Identifiable, Codable, Equatable {
    enum Status: String, Codable {
        case success
        case error
    }

    var id: String
    var timestamp: Date
    var model: String
    var promptTokens: Int
    var completionTokens: Int
    var totalTokens: Int
    var estimatedCost: Double
    var status: Status
    var latencyMs: Int
}

struct TrendPoint: Identifiable, Codable, Equatable {
    var id: String { label }
    var label: String
    var value: Double
}

struct DashboardData: Codable, Equatable {
    var balance: Double
    var maxBalance: Double
    var todayRequests: Int
    var todayTokens: Int
    var todaySpend: Double
    var totalSpend: Double
    var models: [ModelUsageData]
    var recentRequests: [RequestRecord]
    var spendTrend: [TrendPoint]
    var tokensTrend: [TrendPoint]
    var requestsTrend: [TrendPoint]
    var lastUpdatedAt: Date

    static func mock(now: Date = Date()) -> DashboardData {
        func minutesAgo(_ minutes: Double) -> Date {
            now.addingTimeInterval(-minutes * 60)
        }

        let recentRequests: [RequestRecord] = [
            .init(id: "req-001", timestamp: minutesAgo(1), model: "deepseek-v4-flash", promptTokens: 8420, completionTokens: 1240, totalTokens: 9660, estimatedCost: 0.0077, status: .success, latencyMs: 843),
            .init(id: "req-002", timestamp: minutesAgo(3), model: "deepseek-v4-pro", promptTokens: 12300, completionTokens: 2800, totalTokens: 15100, estimatedCost: 0.0453, status: .success, latencyMs: 2341),
            .init(id: "req-003", timestamp: minutesAgo(5), model: "deepseek-v4-flash", promptTokens: 4200, completionTokens: 890, totalTokens: 5090, estimatedCost: 0.0041, status: .success, latencyMs: 512),
            .init(id: "req-004", timestamp: minutesAgo(8), model: "deepseek-v4-flash", promptTokens: 6800, completionTokens: 0, totalTokens: 6800, estimatedCost: 0.0034, status: .error, latencyMs: 12000),
            .init(id: "req-005", timestamp: minutesAgo(12), model: "deepseek-v4-pro", promptTokens: 9100, completionTokens: 3200, totalTokens: 12300, estimatedCost: 0.0369, status: .success, latencyMs: 1987)
        ]

        return DashboardData(
            balance: 83.42,
            maxBalance: 100,
            todayRequests: 142,
            todayTokens: 1_280_000,
            todaySpend: 1.27,
            totalSpend: 16.58,
            models: [
                .init(name: "deepseek-v4-flash", requests: 130, promptTokens: 980_000, completionTokens: 210_000, totalTokens: 1_190_000, estimatedCost: 0.91, percentage: 90.1),
                .init(name: "deepseek-v4-pro", requests: 12, promptTokens: 72_000, completionTokens: 22_000, totalTokens: 94_000, estimatedCost: 0.36, percentage: 9.9)
            ],
            recentRequests: recentRequests,
            spendTrend: [
                .init(label: "04:00", value: 0.12),
                .init(label: "06:00", value: 0.18),
                .init(label: "08:00", value: 0.33),
                .init(label: "10:00", value: 0.54),
                .init(label: "12:00", value: 0.92),
                .init(label: "14:00", value: 1.27)
            ],
            tokensTrend: [
                .init(label: "04:00", value: 88_000),
                .init(label: "06:00", value: 141_000),
                .init(label: "08:00", value: 300_000),
                .init(label: "10:00", value: 620_000),
                .init(label: "12:00", value: 910_000),
                .init(label: "14:00", value: 1_280_000)
            ],
            requestsTrend: [
                .init(label: "04:00", value: 12),
                .init(label: "06:00", value: 19),
                .init(label: "08:00", value: 44),
                .init(label: "10:00", value: 76),
                .init(label: "12:00", value: 111),
                .init(label: "14:00", value: 142)
            ],
            lastUpdatedAt: now
        )
    }
}

struct BalanceSnapshot: Equatable {
    var available: Bool
    var currency: String
    var totalBalance: Double
    var grantedBalance: Double
    var toppedUpBalance: Double
}
