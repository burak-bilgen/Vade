import Foundation

#if canImport(WidgetKit)
import WidgetKit
import SwiftUI
import DesignSystem
#endif

// MARK: - Widget Entry

public struct VadeWidgetEntry: Codable, TimelineEntry, Sendable {
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

// MARK: - Timeline Provider

#if canImport(WidgetKit)
public struct VadeTimelineProvider: TimelineProvider {
    public typealias Entry = VadeWidgetEntry

    public func placeholder(in context: Context) -> VadeWidgetEntry {
        VadeWidgetEntry(
            netBalance: 2500,
            totalReceivable: 5000,
            totalPayable: 2500,
            personCount: 3
        )
    }

    public func getSnapshot(in context: Context, completion: @escaping (VadeWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<VadeWidgetEntry>) -> Void) {
        // Read shared data from App Groups UserDefaults
        let defaults = UserDefaults(suiteName: "group.com.vade.app")
        let balance = Decimal(defaults?.double(forKey: "widget.netBalance") ?? 0)
        let receivable = Decimal(defaults?.double(forKey: "widget.totalReceivable") ?? 0)
        let payable = Decimal(defaults?.double(forKey: "widget.totalPayable") ?? 0)
        let count = defaults?.integer(forKey: "widget.personCount") ?? 0

        let entry = VadeWidgetEntry(
            date: Date(),
            netBalance: balance,
            totalReceivable: receivable,
            totalPayable: payable,
            personCount: count
        )

        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View

public struct VadeWidgetEntryView: View {
    var entry: VadeTimelineProvider.Entry

    public init(entry: VadeTimelineProvider.Entry) {
        self.entry = entry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: "Vade")
                .font(.headline)
                .foregroundColor(Color.vdInk900)

            Text(entry.netBalance.formatted())
                .font(.largeTitle)
                .foregroundColor(entry.netBalance >= 0
                    ? Color.vdPositive600
                    : Color.vdNegative600)

            HStack {
                Label("\(entry.totalReceivable.formatted())", systemImage: "arrow.up")
                    .font(.caption)
                    .foregroundColor(Color.vdPositive600)
                Label("\(entry.totalPayable.formatted())", systemImage: "arrow.down")
                    .font(.caption)
                    .foregroundColor(Color.vdNegative600)
            }

            Text("\(entry.personCount) kişi")
                .font(.caption2)
                .foregroundColor(Color.vdInk400)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Definition

/// Register this widget in the Widget Extension target bundle.
/// Add to Tuist Project.swift as a separate .appExtension target.
public struct VadeWidget: Widget {
    public let kind: String = "com.vade.app.widget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: VadeTimelineProvider()
        ) { entry in
            VadeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Vade Özet")
        .description("Net borç/alacak durumunu tek bakışta gör.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
#endif
