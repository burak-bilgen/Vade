import SwiftUI
import Observation
import Core
import Domain
import Observability

// MARK: - Settings ViewModel

@MainActor
@Observable
public final class SettingsViewModel {
    public var isBiometricEnabled: Bool
    public var isAnalyticsEnabled: Bool
    public var isCrashlyticsEnabled: Bool
    public var preferredCurrency: CurrencyKind

    private let analytics: any AnalyticsTracking

    public init(analytics: any AnalyticsTracking = AnalyticsService()) {
        self.analytics = analytics
        self.isBiometricEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.biometricEnabled)
        self.isAnalyticsEnabled = !UserDefaults.standard.bool(forKey: UserDefaultsKeys.analyticsOptOut)
        self.isCrashlyticsEnabled = !UserDefaults.standard.bool(forKey: UserDefaultsKeys.crashlyticsOptOut)
        let saved = UserDefaults.standard.string(forKey: UserDefaultsKeys.preferredCurrency) ?? CurrencyKind.tryCoin.rawValue
        self.preferredCurrency = CurrencyKind(rawValue: saved) ?? .tryCoin
    }

    public func setBiometric(_ enabled: Bool) {
        isBiometricEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: UserDefaultsKeys.biometricEnabled)
        analytics.track(.biometricLockEnabled(enabled))
    }

    public func setAnalytics(_ enabled: Bool) {
        isAnalyticsEnabled = enabled
        analytics.track(.analyticsOptOut(!enabled))
        if let service = analytics as? AnalyticsService {
            service.setOptOut(!enabled)
        }
        UserDefaults.standard.set(!enabled, forKey: UserDefaultsKeys.analyticsOptOut)
    }

    public func setCrashlytics(_ enabled: Bool) {
        isCrashlyticsEnabled = enabled
        UserDefaults.standard.set(!enabled, forKey: UserDefaultsKeys.crashlyticsOptOut)
    }

    public func setCurrency(_ currency: CurrencyKind) {
        preferredCurrency = currency
        UserDefaults.standard.set(currency.rawValue, forKey: UserDefaultsKeys.preferredCurrency)
    }
}
