import Foundation

// MARK: - UserDefaults Keys

/// Centralized UserDefaults keys to avoid stringly-typed bugs.
/// All UserDefaults access should reference these constants.
public enum UserDefaultsKeys {
    // Settings
    public static let biometricEnabled = "biometric_enabled"
    public static let analyticsOptOut = "analytics_opt_out"
    public static let crashlyticsOptOut = "crashlytics_opt_out"
    public static let appLanguage = "app_language"
    public static let preferredCurrency = "preferred_currency"
    public static let adsEnabled = "vade.ads.enabled"

    // Widget (App Group shared)
    public static let widgetNetBalance = "widget.netBalance"
    public static let widgetTotalReceivable = "widget.totalReceivable"
    public static let widgetTotalPayable = "widget.totalPayable"
    public static let widgetPersonCount = "widget.personCount"
    public static let widgetHasTrackedAdded = "widget.hasTrackedAdded"

    // App Group suite name
    public static let appGroupSuite = "group.com.vade.app"
}
