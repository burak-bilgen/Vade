import Foundation
import Core
import Domain
import os

public final class AnalyticsService: AnalyticsTracking {
    private let _isOptedOut = OSAllocatedUnfairLock(initialState: false)
    private var isOptedOut: Bool {
        get { _isOptedOut.withLock { $0 } }
        set { _isOptedOut.withLock { $0 = newValue } }
    }

    public init() {}

    public func track(_ event: AnalyticsEvent) {
        guard !isOptedOut else { return }
        let (name, parameters) = map(event)
        AppLog.general.info("[Analytics] \(name) params: \(parameters?.description ?? "nil")")
    }

    public func setOptOut(_ optOut: Bool) {
        isOptedOut = optOut
    }

    // MARK: - Event Mapping

    // swiftlint:disable:next cyclomatic_complexity
    private func map(_ event: AnalyticsEvent) -> (String, [String: Any]?) {
        switch event {
        case .appOpened: return ("app_opened", nil)
        case .onboardingCompleted: return ("onboarding_completed", nil)
        case .personAdded: return ("person_added", nil)
        case .debtAdded(let kind): return ("debt_added", ["kind": kind.rawValue])
        case .paymentRecorded(let type): return ("payment_recorded", ["type": type.rawValue])
        case .currencyChanged(let to): return ("currency_changed", ["to": to.rawValue])
        case .exportUsed(let format): return ("export_used", ["format": format.rawValue])
        case .notificationPermission(let g): return ("notification_permission", ["granted": g])
        case .notificationScheduled: return ("notification_scheduled", nil)
        case .widgetAdded: return ("widget_added", nil)
        case .biometricLockEnabled(let e): return ("biometric_lock_enabled", ["enabled": e])
        case .languageChanged(let to): return ("language_changed", ["to": to])
        case .themeChanged(let to): return ("theme_changed", ["to": to.rawValue])
        case .chartViewed(let type): return ("chart_viewed", ["type": type.rawValue])
        case .analyticsOptOut(let o): return ("analytics_opt_out", ["opted_out": o])
        case .dataDeleted: return ("data_deleted", nil)
        }
    }
}
