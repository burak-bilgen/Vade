import Foundation
import Core
import Domain
import Observability

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
        // Store Decimal as String to avoid Double precision loss in UserDefaults
        let defaults = UserDefaults(suiteName: UserDefaultsKeys.appGroupSuite)
        let balance = Decimal(string: defaults?.string(forKey: UserDefaultsKeys.widgetNetBalance) ?? "0", locale: Locale(identifier: "en_US")) ?? .zero
        let receivable = Decimal(string: defaults?.string(forKey: UserDefaultsKeys.widgetTotalReceivable) ?? "0", locale: Locale(identifier: "en_US")) ?? .zero
        let payable = Decimal(string: defaults?.string(forKey: UserDefaultsKeys.widgetTotalPayable) ?? "0", locale: Locale(identifier: "en_US")) ?? .zero
        let count = defaults?.integer(forKey: UserDefaultsKeys.widgetPersonCount) ?? 0

        let entry = VadeWidgetEntry(
            date: Date(),
            netBalance: balance,
            totalReceivable: receivable,
            totalPayable: payable,
            personCount: count
        )

        // Track widget added once (first time timeline is requested after install)
        let hasTrackedWidget = defaults?.bool(forKey: UserDefaultsKeys.widgetHasTrackedAdded) ?? false
        if !hasTrackedWidget {
            let analytics: any AnalyticsTracking = AnalyticsService.shared
            analytics.track(.widgetAdded)
            defaults?.set(true, forKey: UserDefaultsKeys.widgetHasTrackedAdded)
        }

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
            Text(String(localized: "app.name"))
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textPrimary)
                .minimumScaleFactor(0.85)
            Text(String(localized: "app.subtitle"))
                .font(Typography.font(for: .label))
                .foregroundStyle(ColorTokens.textTertiary)
                .minimumScaleFactor(0.75)

            Text(entry.netBalance.formatted())
                .font(Typography.font(for: .title))
                .foregroundStyle(entry.netBalance >= 0
                    ? ColorTokens.positive
                    : ColorTokens.negative)
                .minimumScaleFactor(0.7)

            HStack {
                Label("\(entry.totalReceivable.formatted())", systemImage: "arrow.up")
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(ColorTokens.positive)
                    .minimumScaleFactor(0.85)
                Label("\(entry.totalPayable.formatted())", systemImage: "arrow.down")
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(ColorTokens.negative)
                    .minimumScaleFactor(0.85)
            }

            Text("\(entry.personCount) \(String(localized: "widget.personCount"))")
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textTertiary)
                .minimumScaleFactor(0.85)
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
        .configurationDisplayName(String(localized: "widget.displayName"))
        .description(String(localized: "widget.description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
#endif
