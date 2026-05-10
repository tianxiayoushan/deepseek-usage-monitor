import Foundation
import Observation
import SwiftUI

@Observable
final class SettingsStore {
    @ObservationIgnored private let defaults: UserDefaults

    var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }

    var appTheme: AppTheme {
        didSet { defaults.set(appTheme.rawValue, forKey: Keys.appTheme) }
    }

    var refreshInterval: RefreshInterval {
        didSet { defaults.set(refreshInterval.rawValue, forKey: Keys.refreshInterval) }
    }

    var gaugeMaxAmount: Double {
        didSet { defaults.set(Self.validateGaugeMax(gaugeMaxAmount), forKey: Keys.gaugeMaxAmount) }
    }

    var initialTotalCredit: Double? {
        didSet {
            if let initialTotalCredit {
                defaults.set(max(initialTotalCredit, 0), forKey: Keys.initialTotalCredit)
            } else {
                defaults.removeObject(forKey: Keys.initialTotalCredit)
            }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        language = AppLanguage(rawValue: defaults.string(forKey: Keys.language) ?? "") ?? .zh
        appTheme = AppTheme(rawValue: defaults.string(forKey: Keys.appTheme) ?? "") ?? .dark
        refreshInterval = RefreshInterval(rawValue: defaults.integer(forKey: Keys.refreshInterval)) ?? .five
        gaugeMaxAmount = Self.validateGaugeMax(defaults.double(forKey: Keys.gaugeMaxAmount))

        if defaults.object(forKey: Keys.initialTotalCredit) == nil {
            initialTotalCredit = nil
        } else {
            initialTotalCredit = max(defaults.double(forKey: Keys.initialTotalCredit), 0)
        }
    }

    var preferredColorScheme: ColorScheme? {
        appTheme.preferredColorScheme
    }

    func displayMaxBalance(for balance: Double) -> Double {
        if balance > gaugeMaxAmount {
            return ceil((balance * 1.2) / 10) * 10
        }
        return gaugeMaxAmount
    }

    static func validateGaugeMax(_ value: Double) -> Double {
        guard value >= 100, value <= 1000 else {
            return 100
        }
        return (value / 100).rounded() * 100
    }

    private enum Keys {
        static let language = "ds-native-language"
        static let appTheme = "ds-native-theme"
        static let refreshInterval = "ds-native-refresh-interval"
        static let gaugeMaxAmount = "ds-native-gauge-max-amount"
        static let initialTotalCredit = "ds-native-initial-total-credit"
    }
}
