import Foundation

// MARK: - Type-safe Analytics Event Enum

public enum AnalyticsEvent: Sendable {
    case appOpened
    case onboardingCompleted
    case personAdded
    case debtAdded(kind: DebtKind)
    case paymentRecorded(type: PaymentType)
    case currencyChanged(to: CurrencyCode)
    case exportUsed(format: String)
    case notificationPermission(granted: Bool)
    case notificationScheduled
    case widgetAdded
    case biometricLockEnabled(Bool)
    case languageChanged(to: String)
    case themeChanged(to: ThemeMode)
    case chartViewed(ChartType)
    case analyticsOptOut(Bool)
    case dataDeleted
}

// MARK: - Supporting Types

public enum DebtKind: String, Sendable {
    case cash
    case foreignCurrency
    case gold
}

public enum PaymentType: String, Sendable {
    case full
    case partial
}

public enum CurrencyCode: String, Sendable {
    case tryCoin = "TRY"
    case usd = "USD"
    case eur = "EUR"
    case gold
}



public enum ThemeMode: String, Sendable {
    case system
    case light
    case dark
}

public enum ChartType: String, Sendable {
    case netTimeline
    case receivableVsPayable
    case personDistribution
    case currencyDistribution
    case paidVsPending
    case dueDateHeatmap
    case upcomingTimeline
}
