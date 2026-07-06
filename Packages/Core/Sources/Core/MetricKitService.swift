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

    deinit {
        #if canImport(MetricKit)
        MXMetricManager.shared.remove(self)
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
