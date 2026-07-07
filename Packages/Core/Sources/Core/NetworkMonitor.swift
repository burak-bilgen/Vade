import Foundation
import Network
import Observation

/// A modern, lightweight network connectivity monitor using Swift Observation.
@Observable
@MainActor
public final class NetworkMonitor {
    public static let shared = NetworkMonitor()

    public private(set) var isConnected = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.vade.network.monitor")

    private init() {
        monitor.pathUpdateHandler = { path in
            Task { @MainActor in
                NetworkMonitor.shared.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
