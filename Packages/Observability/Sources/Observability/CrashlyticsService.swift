import Foundation
import OSLog

public protocol CrashReporting: Sendable {
    func recordError(_ error: Error)
    func setCustomValue(_ value: String, forKey key: String)
}

public final class CrashlyticsService: CrashReporting {
    private let logger = Logger(subsystem: "com.vade.observability", category: "crashlytics")

    public init() {}

    public func recordError(_ error: Error) {
        logger.error("[Crashlytics] Recorded: \(error.localizedDescription)")
    }

    public func setCustomValue(_ value: String, forKey key: String) {
        logger.info("[Crashlytics] Set key '\(key)'")
    }
}
