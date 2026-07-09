import SwiftUI
import DesignSystem
import Domain
import Observability

#if canImport(Charts)
import Charts
#endif

// MARK: - Chart Animations

let chartAnimation: Animation = .easeInOut(duration: 0.6)

// MARK: - Chart Data Point

public struct ChartDataPoint: Identifiable, Sendable {
    public let id = UUID()
    public let label: String
    public let value: Decimal
    public let color: Color

    public init(label: String, value: Decimal, color: Color) {
        self.label = label
        self.value = value
        self.color = color
    }
}

// MARK: - Monthly Trend Chart (LineMark)

/// Shows net balance trend over the last 6 months.
/// Uses LineMark with gradient fill below the line.
public struct MonthlyTrendChart: View {
    let monthlyData: [(month: String, receivable: Decimal, payable: Decimal, net: Decimal)]
    private let analytics: any AnalyticsTracking = AnalyticsService.shared

    public init(monthlyData: [(month: String, receivable: Decimal, payable: Decimal, net: Decimal)]) {
        self.monthlyData = monthlyData
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(String(localized: "charts.monthlyTrend.title"))
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)

            if monthlyData.isEmpty {
                emptyChartPlaceholder
            } else {
                #if canImport(Charts)
                Chart {
                    ForEach(monthlyData, id: \.month) { item in
                        LineMark(
                            x: .value("Month", item.month),
                            y: .value("Net", NSDecimalNumber(decimal: item.net).doubleValue)
                        )
                        .foregroundStyle(ColorTokens.accent)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Month", item.month),
                            y: .value("Net", NSDecimalNumber(decimal: item.net).doubleValue)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ColorTokens.accent.opacity(0.3), ColorTokens.accent.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Month", item.month),
                            y: .value("Net", NSDecimalNumber(decimal: item.net).doubleValue)
                        )
                        .foregroundStyle(ColorTokens.accent)
                        .symbolSize(30)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartLegend(position: .bottom, alignment: .center)
                .animation(chartAnimation, value: monthlyData.count)
                .frame(height: 200)
            #else
            Text(String(localized: "charts.unavailable"))
                .foregroundStyle(ColorTokens.textTertiary)
            #endif
            }
        }
        .task {
            analytics.track(.chartViewed(.netTimeline))
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundStyle(ColorTokens.textTertiary)
            Text(String(localized: "charts.monthlyTrend.empty"))
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }
}

// MARK: - Debt Status Distribution Chart (SectorMark)

/// Donut chart showing pending vs paid vs archived debt distribution.
public struct DebtStatusChart: View {
    let pendingCount: Int
    let paidCount: Int
    let archivedCount: Int
    private let analytics: any AnalyticsTracking = AnalyticsService.shared

    public init(pendingCount: Int, paidCount: Int, archivedCount: Int) {
        self.pendingCount = pendingCount
        self.paidCount = paidCount
        self.archivedCount = archivedCount
    }

    private var totalCount: Int { pendingCount + paidCount + archivedCount }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(String(localized: "charts.status.title"))
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)

            if totalCount == 0 {
                emptyChartPlaceholder
            } else {
                #if canImport(Charts)
                Chart {
                    if pendingCount > 0 {
                        SectorMark(
                            angle: .value("Count", pendingCount),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(ColorTokens.chartOrange)
                        .annotation(position: .overlay) {
                            Text("\(pendingCount)")
                                .font(Typography.font(for: .caption))
                                .foregroundStyle(.white)
                        }
                    }

                    if paidCount > 0 {
                        SectorMark(
                            angle: .value("Count", paidCount),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(ColorTokens.positive)
                    }

                    if archivedCount > 0 {
                        SectorMark(
                            angle: .value("Count", archivedCount),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(ColorTokens.textTertiary)
                    }
                }
                .chartLegend(position: .bottom, alignment: .center)
                .animation(chartAnimation, value: totalCount)
                .frame(height: 180)
                .overlay(alignment: .center) {
                    VStack(spacing: 0) {
                        Text("\(totalCount)")
                            .font(Typography.font(for: .title))
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text(String(localized: "charts.status.total"))
                            .font(Typography.font(for: .label))
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                }
                #else
                Text(String(localized: "charts.unavailable"))
                    .foregroundStyle(ColorTokens.textTertiary)
                #endif

                // Legend
                HStack(spacing: Spacing.l) {
                    legendItem(color: ColorTokens.chartOrange, label: String(localized: "charts.status.pending"), count: pendingCount)
                    legendItem(color: ColorTokens.positive, label: String(localized: "charts.status.paid"), count: paidCount)
                    legendItem(color: ColorTokens.textTertiary, label: String(localized: "charts.status.archived"), count: archivedCount)
                }
            }
        }
        .task {
            analytics.track(.chartViewed(.receivableVsPayable))
        }
    }

    private func legendItem(color: Color, label: String, count: Int) -> some View {
        HStack(spacing: Spacing.xxs) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(Typography.font(for: .label))
                .foregroundStyle(ColorTokens.textTertiary)
            Text("\(count)")
                .font(Typography.font(for: .label))
                .foregroundStyle(ColorTokens.textSecondary)
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: "chart.pie")
                .font(.system(size: 32))
                .foregroundStyle(ColorTokens.textTertiary)
            Text(String(localized: "charts.status.empty"))
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }
}

// MARK: - Currency Trend Chart (AreaMark)

/// Shows currency distribution as stacked area chart.
public struct CurrencyTrendChart: View {
    let distribution: [(kind: CurrencyKind, total: Decimal)]
    private let analytics: any AnalyticsTracking = AnalyticsService.shared

    public init(distribution: [(kind: CurrencyKind, total: Decimal)]) {
        self.distribution = distribution
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(String(localized: "charts.currency.title"))
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)

            if distribution.isEmpty {
                emptyChartPlaceholder
            } else {
                #if canImport(Charts)
                Chart {
                    ForEach(distribution, id: \.kind) { item in
                        BarMark(
                            x: .value("Currency", item.kind.displayName)
                            y: .value("Total", NSDecimalNumber(decimal: item.total).doubleValue)
                        )
                        .foregroundStyle(barColor(for: item.kind))
                        .cornerRadius(Radius.xs)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartLegend(position: .bottom, alignment: .center)
                .animation(chartAnimation, value: distribution.count)
                .frame(height: 160)
                #else
                Text(String(localized: "charts.unavailable"))
                    .foregroundStyle(ColorTokens.textTertiary)
                #endif
            }
        }
        .task {
            analytics.track(.chartViewed(.currencyDistribution))
        }
    }

    private func barColor(for kind: CurrencyKind) -> Color {
        switch kind {
        case .tryCoin: return ColorTokens.chartBlue
        case .usd: return ColorTokens.chartTeal
        case .eur: return ColorTokens.chartPurple
        case .goldGram, .goldQuarter, .goldHalf, .goldFull, .goldRepublic: return ColorTokens.chartOrange
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 32))
                .foregroundStyle(ColorTokens.textTertiary)
            Text(String(localized: "charts.currency.empty"))
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }
}

// MARK: - Upcoming Payments Timeline (PointMark + RuleMark)

/// Shows upcoming due dates on a timeline with amounts.
public struct UpcomingTimelineChart: View {
    let items: [(person: String, amount: Decimal, dueDate: Date)]
    private let analytics: any AnalyticsTracking = AnalyticsService.shared

    public init(items: [(person: String, amount: Decimal, dueDate: Date)]) {
        self.items = items
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(String(localized: "charts.upcoming.title"))
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)

            if items.isEmpty {
                emptyChartPlaceholder
            } else {
                #if canImport(Charts)
                Chart {
                    // Today reference line
                    RuleMark(x: .value("Today", Date()))
                        .foregroundStyle(ColorTokens.accent.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top) {
                            Text(String(localized: "charts.upcoming.today"))
                                .font(Typography.font(for: .label))
                                .foregroundStyle(ColorTokens.accent)
                        }

                    ForEach(items, id: \.person) { item in
                        PointMark(
                            x: .value("Date", item.dueDate),
                            y: .value("Amount", NSDecimalNumber(decimal: item.amount).doubleValue)
                        )
                        .foregroundStyle(ColorTokens.chartOrange)
                        .symbolSize(80)
                        .annotation(position: .top) {
                            Text(item.person)
                                .font(Typography.font(for: .label))
                                .foregroundStyle(ColorTokens.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7))
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartLegend(position: .bottom, alignment: .center)
                .animation(chartAnimation, value: items.count)
                .frame(height: 180)
                #else
                Text(String(localized: "charts.unavailable"))
                    .foregroundStyle(ColorTokens.textTertiary)
                #endif
            }
        }
        .task {
            analytics.track(.chartViewed(.upcomingTimeline))
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 32))
                .foregroundStyle(ColorTokens.textTertiary)
            Text(String(localized: "charts.upcoming.empty"))
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }
}

// MARK: - Net Balance Chart (legacy)

public struct NetBalanceChart: View {
    let dataPoints: [ChartDataPoint]
    let netBalance: Decimal
    private let analytics: any AnalyticsTracking = AnalyticsService.shared

    public init(dataPoints: [ChartDataPoint], netBalance: Decimal) {
        self.dataPoints = dataPoints
        self.netBalance = netBalance
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(String(localized: "charts.netBalance.title"))
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)

            #if canImport(Charts)
            Chart(dataPoints) { point in
                BarMark(
                    x: .value("Label", point.label),
                    y: .value("Value", NSDecimalNumber(decimal: point.value).doubleValue)
                )
                .foregroundStyle(point.color)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartLegend(position: .bottom, alignment: .center)
            .animation(chartAnimation, value: dataPoints.count)
            .frame(height: 200)
            #else
            Text(String(localized: "charts.unavailable"))
                .foregroundStyle(ColorTokens.textTertiary)
            #endif
        }
        .task {
            analytics.track(.chartViewed(.netTimeline))
        }
    }
}

// MARK: - Direction Pie Chart (legacy)

public struct DirectionPieChart: View {
    let receivable: Decimal
    let payable: Decimal
    private let analytics: any AnalyticsTracking = AnalyticsService.shared

    public init(receivable: Decimal, payable: Decimal) {
        self.receivable = receivable
        self.payable = payable
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(String(localized: "charts.direction.title"))
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)

            #if canImport(Charts)
            let data: [ChartDataPoint] = [
                ChartDataPoint(
                    label: String(localized: "charts.direction.receivable"),
                    value: receivable,
                    color: ColorTokens.positive
                ),
                ChartDataPoint(
                    label: String(localized: "charts.direction.payable"),
                    value: payable,
                    color: ColorTokens.negative
                ),
            ]

            Chart(data) { point in
                SectorMark(
                    angle: .value("Value", NSDecimalNumber(decimal: max(point.value, 0.01)).doubleValue),
                    innerRadius: .ratio(0.5),
                    angularInset: 1
                )
                .foregroundStyle(point.color)
            }
            .chartLegend(position: .bottom, alignment: .center)
            .animation(chartAnimation, value: receivable + payable)
            .frame(height: 200)
            #else
            Text(String(localized: "charts.unavailable"))
                .foregroundStyle(ColorTokens.textTertiary)
            #endif
        }
        .task {
            analytics.track(.chartViewed(.receivableVsPayable))
        }
    }
}

// MARK: - Person Distribution Chart (Horizontal Bar)

public struct PersonDistributionChart: View {
    let personBalances: [(name: String, balance: Decimal)]
    private let analytics: any AnalyticsTracking = AnalyticsService.shared

    public init(personBalances: [(name: String, balance: Decimal)]) {
        self.personBalances = personBalances
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(String(localized: "charts.personDistribution.title"))
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)

            if personBalances.isEmpty {
                emptyChartPlaceholder
            } else {
                #if canImport(Charts)
                Chart(personBalances, id: \.name) { item in
                    BarMark(
                        x: .value("Balance", NSDecimalNumber(decimal: abs(item.balance)).doubleValue),
                        y: .value("Person", item.name)
                    )
                    .foregroundStyle(item.balance >= 0 ? ColorTokens.positive : ColorTokens.negative)
                    .cornerRadius(Radius.xs)
                    .annotation(position: .trailing) {
                        Text(item.balance.formatted())
                            .font(Typography.font(for: .label))
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .chartLegend(position: .bottom, alignment: .center)
                .animation(chartAnimation, value: personBalances.count)
                .frame(height: max(120, CGFloat(personBalances.count * 40)))
                #else
                Text(String(localized: "charts.unavailable"))
                    .foregroundStyle(ColorTokens.textTertiary)
                #endif
            }
        }
        .task {
            analytics.track(.chartViewed(.personDistribution))
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: "person.2")
                .font(.system(size: 32))
                .foregroundStyle(ColorTokens.textTertiary)
            Text(String(localized: "charts.personDistribution.empty"))
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }
}

// MARK: - Paid vs Pending Amount Chart

public struct PaidVsPendingAmountChart: View {
    let paidAmount: Decimal
    let pendingAmount: Decimal
    private let analytics: any AnalyticsTracking = AnalyticsService.shared

    public init(paidAmount: Decimal, pendingAmount: Decimal) {
        self.paidAmount = paidAmount
        self.pendingAmount = pendingAmount
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(String(localized: "charts.paidVsPending.title"))
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)

            if paidAmount == 0 && pendingAmount == 0 {
                emptyChartPlaceholder
            } else {
                #if canImport(Charts)
                Chart {
                    BarMark(
                        x: .value("Type", String(localized: "charts.status.paid")),
                        y: .value("Amount", NSDecimalNumber(decimal: paidAmount).doubleValue)
                    )
                    .foregroundStyle(ColorTokens.positive)
                    .cornerRadius(Radius.xs)

                    BarMark(
                        x: .value("Type", String(localized: "charts.status.pending")),
                        y: .value("Amount", NSDecimalNumber(decimal: pendingAmount).doubleValue)
                    )
                    .foregroundStyle(ColorTokens.chartOrange)
                    .cornerRadius(Radius.xs)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartLegend(position: .bottom, alignment: .center)
                .animation(chartAnimation, value: paidAmount + pendingAmount)
                .frame(height: 200)
                #else
                Text(String(localized: "charts.unavailable"))
                    .foregroundStyle(ColorTokens.textTertiary)
                #endif
            }
        }
        .task {
            analytics.track(.chartViewed(.paidVsPending))
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 32))
                .foregroundStyle(ColorTokens.textTertiary)
            Text(String(localized: "charts.paidVsPending.empty"))
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }
}

// MARK: - Previews

#Preview {
    ScrollView {
        VStack(spacing: Spacing.l) {
            MonthlyTrendChart(monthlyData: [
                ("Jan", 1000, 500, 500),
                ("Feb", 2000, 800, 1200),
                ("Mar", 1500, 2000, -500),
                ("Apr", 3000, 1000, 2000),
                ("May", 2500, 1500, 1000),
                ("Jun", 4000, 2000, 2000),
            ])
            DebtStatusChart(pendingCount: 5, paidCount: 3, archivedCount: 1)
            CurrencyTrendChart(distribution: [
                (.tryCoin, 5000),
                (.usd, 2000),
                (.eur, 1000),
                (.goldGram, 500),
            ])
            UpcomingTimelineChart(items: [
                ("Alice", 1500, Date().addingTimeInterval(86400 * 3)),
                ("Bob", 750, Date().addingTimeInterval(86400 * 7)),
                ("Charlie", 2000, Date().addingTimeInterval(86400 * 14)),
            ])
            PersonDistributionChart(personBalances: [
                ("Alice", 2500),
                ("Bob", -1200),
                ("Charlie", 800),
            ])
            PaidVsPendingAmountChart(paidAmount: 3500, pendingAmount: 8200)
        }
        .padding()
    }
    .background(ColorTokens.background)
}
