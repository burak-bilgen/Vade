import Foundation
import Core
import OSLog

#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

// MARK: - Ad Service Protocol

public protocol AdProviding: Sendable {
    var isAdsEnabled: Bool { get }
    func setAdsEnabled(_ enabled: Bool)
}

// MARK: - Ad Service (Placeholder — GoogleAdMob SDK integration point)

/// Manages AdMob banner display and ATT (App Tracking Transparency) flow.
/// Google Mobile Ads SDK must be added to the main app target via SPM.
/// Ad unit IDs are configured in the app's Info.plist.
public final class AdService: AdProviding {
    private let logger = Logger(subsystem: "com.vade.observability", category: "ads")
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var isAdsEnabled: Bool {
        defaults.bool(forKey: UserDefaultsKeys.adsEnabled)
    }

    public func setAdsEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: UserDefaultsKeys.adsEnabled)
        logger.info("[AdService] Ads \(enabled ? "enabled" : "disabled")")
    }
}

// MARK: - ATT Flow Placeholder

/// Wraps App Tracking Transparency authorization request.
/// Call `requestTrackingPermission()` before showing personalized ads.
/// Requires NSUserTrackingUsageDescription in Info.plist.
@MainActor
public enum ATTrackingFlow {
    private static let logger = Logger(subsystem: "com.vade.observability", category: "att")

    #if canImport(AppTrackingTransparency)
    public static func requestPermission() async -> Bool {
        let status = await ATTrackingManager.requestTrackingAuthorization()
        logger.info("[ATT] Status: \(status.rawValue)")
        return status == .authorized
    }
    #else
    public static func requestPermission() async -> Bool {
        return false
    }
    #endif
}
