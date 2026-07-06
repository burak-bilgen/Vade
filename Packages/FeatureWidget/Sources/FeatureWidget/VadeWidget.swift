import Foundation

// MARK: - Widget Entry

/// Timeline entry for the Vade widget.
/// Populated in Phase 5 with real data from the main app's shared container.
public struct VadeWidgetEntry: Codable, Sendable {
    public let date: Date
    public let netBalance: Decimal
    public let totalReceivable: Decimal
    public let totalPayable: Decimal
    public let personCount: Int

    public init(
        date: Date = Date(),
        netBalance: Decimal = .zero,
        totalReceivable: Decimal = .zero,
        totalPayable: Decimal = .zero,
        personCount: Int = 0
    ) {
        self.date = date
        self.netBalance = netBalance
        self.totalReceivable = totalReceivable
        self.totalPayable = totalPayable
        self.personCount = personCount
    }
}

// MARK: - Widget Provider (skeleton)

/// TimelineProvider implementation — Phase 5 will connect to WidgetKit.
/// Current placeholder: provides static snapshot data until App Groups sharing is configured.
public enum VadeWidgetProvider {
    public static func placeholder() -> VadeWidgetEntry {
        VadeWidgetEntry(
            netBalance: 2500,
            totalReceivable: 5000,
            totalPayable: 2500,
            personCount: 3
        )
    }
}
