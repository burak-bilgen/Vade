import SwiftUI
import DesignSystem
import Domain
import Networking

// MARK: - Charts Host View

/// Rich analytics page displaying all chart types with real data.
public struct ChartsHostView: View {
    let totalReceivable: Decimal
    let totalPayable: Decimal
    let netBalance: Decimal
    let monthlyTrendData: [(month: String, receivable: Decimal, payable: Decimal, net: Decimal)]
    let pendingCount: Int
    let paidCount: Int
    let archivedCount: Int
    let currencyDistribution: [(kind: CurrencyKind, total: Decimal)]
    let upcomingItems: [(person: String, amount: Decimal, dueDate: Date)]
    let personCount: Int
    let personBalances: [(name: String, balance: Decimal)]
    let paidAmount: Decimal
    let pendingAmount: Decimal

    @State private var lastRateUpdateInfo: String?
    @State private var selectedChartType: ChartSection = .overview

    public init(
        totalReceivable: Decimal,
        totalPayable: Decimal,
        netBalance: Decimal,
        monthlyTrendData: [(month: String, receivable: Decimal, payable: Decimal, net: Decimal)] = [],
        pendingCount: Int = 0,
        paidCount: Int = 0,
        archivedCount: Int = 0,
        currencyDistribution: [(kind: CurrencyKind, total: Decimal)] = [],
        upcomingItems: [(person: String, amount: Decimal, dueDate: Date)] = [],
        personCount: Int = 0,
        personBalances: [(name: String, balance: Decimal)] = [],
        paidAmount: Decimal = .zero,
        pendingAmount: Decimal = .zero
    ) {
        self.totalReceivable = totalReceivable
        self.totalPayable = totalPayable
        self.netBalance = netBalance
        self.monthlyTrendData = monthlyTrendData
        self.pendingCount = pendingCount
        self.paidCount = paidCount
        self.archivedCount = archivedCount
        self.currencyDistribution = currencyDistribution
        self.upcomingItems = upcomingItems
        self.personCount = personCount
        self.personBalances = personBalances
        self.paidAmount = paidAmount
        self.pendingAmount = pendingAmount
    }

    enum ChartSection: String, CaseIterable {
        case overview
        case trends
        case distribution
        case people
        case upcoming
    }

    public var body: some View {
        ZStack {
            FinanceBackgroundAnimation()
                .ignoresSafeArea()
            ColorTokens.background.opacity(0.12).ignoresSafeArea()

            if !hasData {
                ChartsSkeleton()
                    .entrance(.fade)
            } else {
                content
            }
        }
        .navigationTitle("dashboard.viewStatistics")
        .task {
            await loadRateStaleness()
            withAnimation(.easeOut(duration: 0.4)) { hasData = true }
        }
    }

    @Environment(\.locale) private var locale
    @State private var hasData = false

    private var content: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Quick stats header
                quickStatsGrid

                // Section picker
                Picker("", selection: $selectedChartType) {
                    Text("charts.section.overview").tag(ChartSection.overview)
                    Text("charts.section.trends").tag(ChartSection.trends)
                    Text("charts.section.distribution").tag(ChartSection.distribution)
                    Text("charts.section.people").tag(ChartSection.people)
                    Text("charts.section.upcoming").tag(ChartSection.upcoming)
                }
                .pickerStyle(.segmented)
                .tint(ColorTokens.accent)
                .padding(.horizontal, Spacing.l)

                switch selectedChartType {
                case .overview:
                    overviewSection
                case .trends:
                    trendsSection
                case .distribution:
                    distributionSection
                case .people:
                    peopleSection
                case .upcoming:
                    upcomingSection
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.l)
        }

    }

    // MARK: - Quick Stats Grid

    private var quickStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.m) {
            StatTile(
                title: "dashboard.summary.totalReceivable",
                value: totalReceivable.formatted(),
                color: ColorTokens.positive,
                icon: "arrow.down.left"
            )
            StatTile(
                title: "dashboard.summary.totalPayable",
                value: totalPayable.formatted(),
                color: ColorTokens.negative,
                icon: "arrow.up.right"
            )
            StatTile(
                title: "charts.netBalance.short",
                value: netBalance.formatted(),
                color: netBalance >= 0 ? ColorTokens.positive : ColorTokens.negative,
                icon: "equal"
            )
            StatTile(
                title: "charts.status.total",
                value: "\(personCount)",
                color: ColorTokens.accent,
                icon: "person.2"
            )
        }
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(spacing: Spacing.l) {
            // Monthly trend (compact)
            chartCard(title: String(localized: "charts.monthlyTrend.title", locale: locale)) {
                MonthlyTrendChart(monthlyData: monthlyTrendData)
            }

            // Status distribution
            chartCard(title: String(localized: "charts.status.title", locale: locale)) {
                DebtStatusChart(pendingCount: pendingCount, paidCount: paidCount, archivedCount: archivedCount)
            }
        }
    }

    // MARK: - Trends Section

    private var trendsSection: some View {
        VStack(spacing: Spacing.l) {
            chartCard(title: String(localized: "charts.monthlyTrend.title", locale: locale)) {
                MonthlyTrendChart(monthlyData: monthlyTrendData)
            }

            chartCard(title: String(localized: "charts.netBalance.title", locale: locale)) {
                let netDataPoints: [ChartDataPoint] = [
                    ChartDataPoint(label: String(localized: "charts.direction.receivable", locale: locale), value: totalReceivable, color: ColorTokens.positive),
                    ChartDataPoint(label: String(localized: "charts.direction.payable", locale: locale), value: totalPayable, color: ColorTokens.negative),
                ]
                NetBalanceChart(dataPoints: netDataPoints, netBalance: netBalance)
            }
        }
    }

    // MARK: - Distribution Section

    private var distributionSection: some View {
        VStack(spacing: Spacing.l) {
            chartCard(title: String(localized: "charts.direction.title", locale: locale)) {
                DirectionPieChart(receivable: totalReceivable, payable: totalPayable)
            }

            chartCard(title: String(localized: "charts.currency.title", locale: locale)) {
                CurrencyTrendChart(distribution: currencyDistribution)
            }

            // Exchange rate info
            if let info = lastRateUpdateInfo {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(ColorTokens.textTertiary)
                    Text(info)
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textTertiary)
                }
            }
        }
    }

    // MARK: - People Section

    private var peopleSection: some View {
        VStack(spacing: Spacing.l) {
            chartCard(title: String(localized: "charts.personDistribution.title", locale: locale)) {
                PersonDistributionChart(personBalances: personBalances)
            }

            chartCard(title: String(localized: "charts.paidVsPending.title", locale: locale)) {
                PaidVsPendingAmountChart(paidAmount: paidAmount, pendingAmount: pendingAmount)
            }
        }
    }

    // MARK: - Upcoming Section

    private var upcomingSection: some View {
        VStack(spacing: Spacing.l) {
            chartCard(title: String(localized: "charts.upcoming.title", locale: locale)) {
                UpcomingTimelineChart(items: upcomingItems)
            }

            // List upcoming items
            if !upcomingItems.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text("dashboard.upcoming.title")
                        .font(Typography.font(for: .title2))
                        .foregroundStyle(ColorTokens.textPrimary)

                    ForEach(upcomingItems.sorted { $0.dueDate < $1.dueDate }, id: \.person) { item in
                        HStack(spacing: Spacing.m) {
                            Circle()
                                .fill(ColorTokens.chartOrange)
                                .frame(width: 8, height: 8)
                            Text(item.person)
                                .font(Typography.font(for: .bodyEmphasis))
                                .foregroundStyle(ColorTokens.textPrimary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(item.amount.formatted())
                                    .font(Typography.font(for: .amount))
                                    .foregroundStyle(ColorTokens.textPrimary)
                                Text(item.dueDate, format: .dateTime.day().month(.abbreviated))
                                    .font(Typography.font(for: .label))
                                    .foregroundStyle(ColorTokens.textTertiary)
                            }
                        }
                        .padding(.horizontal, Spacing.l)
                        .padding(.vertical, Spacing.s)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .fill(ColorTokens.surface)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func chartCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(ColorTokens.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .stroke(ColorTokens.border, lineWidth: 0.5)
        )
    }

    private func loadRateStaleness() async {
        let client = ExchangeRateClient()
        guard let lastDate = await client.lastUpdateDate() else { return }
        let elapsed = Date().timeIntervalSince(lastDate)
        let hours = Int(elapsed / 3600)
        if hours >= 1 {
            let format = String(localized: "exchangeRate.stale", locale: locale)
            lastRateUpdateInfo = String(format: format, hours)
        } else {
            lastRateUpdateInfo = nil
        }
    }
}

// MARK: - Stat Tile

private struct StatTile: View {
    let title: LocalizedStringKey
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(Typography.font(for: .label))
                    .foregroundStyle(ColorTokens.textTertiary)
            }
            Text(value)
                .font(Typography.font(for: .headline))
                .foregroundStyle(ColorTokens.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(ColorTokens.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(ColorTokens.border, lineWidth: 0.5)
        )
    }
}

// MARK: - Charts Loading Skeleton

private struct ChartsSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Stats grid skeleton
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.m) {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonCard(lines: 1)
                            .frame(height: 64)
                    }
                }
                .padding(.horizontal, Spacing.l)

                // Section picker skeleton
                ShimmerView(cornerRadius: Radius.md)
                    .frame(height: 36)
                    .padding(.horizontal, Spacing.l)

                // Chart card skeletons
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonCard(lines: 4)
                        .frame(height: 220)
                        .padding(.horizontal, Spacing.l)
                }
            }
            .padding(.vertical, Spacing.l)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ChartsHostView(
            totalReceivable: 15000,
            totalPayable: 8500,
            netBalance: 6500,
            monthlyTrendData: [
                ("Oca", 1000, 500, 500),
                ("Şub", 2000, 800, 1200),
                ("Mar", 1500, 2000, -500),
                ("Nis", 3000, 1000, 2000),
                ("May", 2500, 1500, 1000),
                ("Haz", 4000, 2000, 2000),
            ],
            pendingCount: 5,
            paidCount: 3,
            archivedCount: 1,
            currencyDistribution: [
                (.tryCoin, 8000),
                (.usd, 3000),
                (.eur, 2000),
            ],
            upcomingItems: [
                ("Ahmet", 1500, Date().addingTimeInterval(86400 * 3)),
                ("Ayşe", 750, Date().addingTimeInterval(86400 * 7)),
            ],
            personCount: 3
        )
    }
}
#endif
