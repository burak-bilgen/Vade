import SwiftUI
import Observation
import Domain
import Observability

// MARK: - Settings ViewModel

@MainActor
@Observable
public final class SettingsViewModel {
    public var isBiometricEnabled: Bool
    public var isAnalyticsEnabled: Bool
    public var isCrashlyticsEnabled: Bool
    public var selectedLanguage: String

    private let analytics: any AnalyticsTracking

    public init(analytics: any AnalyticsTracking = AnalyticsService()) {
        self.analytics = analytics
        // Read from AppStorage via UserDefaults
        self.isBiometricEnabled = UserDefaults.standard.bool(forKey: "biometric_enabled")
        self.isAnalyticsEnabled = !UserDefaults.standard.bool(forKey: "analytics_opt_out")
        self.isCrashlyticsEnabled = !UserDefaults.standard.bool(forKey: "crashlytics_opt_out")
        self.selectedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "tr"
    }

    public func setBiometric(_ enabled: Bool) {
        isBiometricEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "biometric_enabled")
        analytics.track(.biometricLockEnabled(enabled))
    }

    public func setAnalytics(_ enabled: Bool) {
        isAnalyticsEnabled = enabled
        analytics.track(.analyticsOptOut(!enabled))
        if let service = analytics as? AnalyticsService {
            service.setOptOut(!enabled)
        }
        UserDefaults.standard.set(!enabled, forKey: "analytics_opt_out")
    }

    public func setCrashlytics(_ enabled: Bool) {
        isCrashlyticsEnabled = enabled
        UserDefaults.standard.set(!enabled, forKey: "crashlytics_opt_out")
    }

    public func setLanguage(_ lang: String) {
        selectedLanguage = lang
        UserDefaults.standard.set(lang, forKey: "app_language")
        analytics.track(.languageChanged(to: lang))
    }
}
