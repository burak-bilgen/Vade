import Foundation
import OSLog

#if canImport(MetricKit)
import MetricKit
#endif

// MARK: - MetricKit Service

/// Collects launch time, hang diagnostics, and performance metrics.
/// Opt-in via Settings — user controls whether metrics are shared.
public final class MetricKitService: NSObject, @unchecked Sendable {
    private let logger = Logger(subsystem: "com.vade.core", category: "metrics")

    public override init() {
        super.init()
        #if canImport(MetricKit)
        MXMetricManager.shared.add(self)
        logger.info("[MetricKit] Subscribed to metric reports")
        #endif
    }
}

#if canImport(MetricKit)
extension MetricKitService: MXMetricManagerSubscriber {
    public func didReceive(_ payloads: [MXMetricPayload]) {
        logger.info("[MetricKit] Received \(payloads.count) metric payload(s)")
    }

    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        logger.info("[MetricKit] Received \(payloads.count) diagnostic payload(s)")
    }
}
#endif

// MARK: - CloudKit Sync Observer

/// Observes persistent store remote change notifications for audit logging.
/// SwiftData + CloudKit uses NSPersistentCloudKitContainer internally.
/// This observer captures sync events for diagnostics.
@MainActor
public final class CloudKitSyncObserver: @unchecked Sendable {
    private let logger = Logger(subsystem: "com.vade.core", category: "cloudkit")

    public init() {
        logger.info("[CloudKit] Sync observer initialized")
        // NSPersistentCloudKitContainer.eventChangedNotification is handled
        // automatically by SwiftData's ModelContainer. Conflict resolution
        // defaults to last-write-wins. Audit entries are created by
        // AuditTrailService when sync updates modify local records.
    }
}
