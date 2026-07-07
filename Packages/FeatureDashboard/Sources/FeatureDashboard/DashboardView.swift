import SwiftUI
import DesignSystem
import Domain
import Core
import Observability
import Networking

// MARK: - Dashboard

public struct DashboardView: View {
    @State private var viewModel: DashboardViewModel?
    @State private var showAdd = false
    private let analytics: any AnalyticsTracking = AnalyticsService.shared

    private let personRepo: AddPersonUseCase & FetchPersonsUseCase
    private let debtRepo: AddDebtUseCase & FetchDebtsForPersonUseCase
    private let balanceRepo: CalculateBalanceUseCase
    private let paymentRepo: RecordPaymentUseCase & FetchPaymentsForDebtUseCase
    private let rateClient: ExchangeRateProviding

    public init(
        personRepo: AddPersonUseCase & FetchPersonsUseCase,
        debtRepo: AddDebtUseCase & FetchDebtsForPersonUseCase,
        balanceRepo: CalculateBalanceUseCase,
        paymentRepo: RecordPaymentUseCase & FetchPaymentsForDebtUseCase,
        rateClient: ExchangeRateProviding = ExchangeRateClient()
    ) {
        self.personRepo = personRepo
        self.debtRepo = debtRepo
        self.balanceRepo = balanceRepo
        self.paymentRepo = paymentRepo
        self.rateClient = rateClient
    }

    @State private var contentAppeared = false

    public var body: some View {
        Group {
            if viewModel == nil {
                DashboardSkeleton()
                    .entrance(.fade)
            } else if let vm = viewModel {
                content(vm)
            }
        }
        .background(ColorTokens.background)
        .ignoresSafeArea(.container, edges: .top)
        .sheet(isPresented: $showAdd) {
            QuickAddSheet(
                personRepo: personRepo,
                debtRepo: debtRepo,
                onDone: { await viewModel?.loadData() }
            )
        }
        .task {
            let vm = DashboardViewModel(
                personRepo: personRepo,
                debtRepo: debtRepo,
                balanceRepo: balanceRepo,
                rateClient: rateClient
            )
            viewModel = vm
            await vm.loadData()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                contentAppeared = true
            }
        }
        .refreshable {
            HapticFeedback.impact(.medium)
            await viewModel?.loadData()
        }
    }

    private func content(_ vm: DashboardViewModel) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection(vm)
                contentSection(vm)
            }
        }
    }

    // MARK: - Header with Premium Balance Card

    private func headerSection(_ vm: DashboardViewModel) -> some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 60)

            // Greeting + compact action row
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(timeGreeting)
                        .font(Typography.font(for: .label))
                        .foregroundStyle(ColorTokens.textTertiary)
                    Text(String(localized: "app.name"))
                        .font(Typography.font(for: .title))
                        .foregroundStyle(ColorTokens.textPrimary)
                }
                Spacer()
                HStack(spacing: Spacing.s) {
                    NavigationLink(destination: {
                        ChartsHostView(
                            totalReceivable: vm.totalReceivable,
                            totalPayable: vm.totalPayable,
                            netBalance: vm.netBalance,
                            monthlyTrendData: vm.monthlyTrendData,
                            pendingCount: vm.pendingDebtCount,
                            paidCount: vm.paidDebtCount,
                            archivedCount: vm.archivedDebtCount,
                            currencyDistribution: vm.currencyDistribution,
                            upcomingItems: vm.upcomingChartItems,
                            personCount: vm.persons.count,
                            personBalances: vm.personBalances,
                            paidAmount: vm.paidAmount,
                            pendingAmount: vm.pendingAmount
                        )
                    }) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(ColorTokens.chartPurple)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(ColorTokens.chartPurple.opacity(0.12)))
                    }
                    .premiumPress()

                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(ColorTokens.accent))
                    }
                    .premiumPress()
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.m)
            .entrance(.up, delay: 0.05)

            // Premium Balance Card
            PremiumBalanceCard(
                netAmount: vm.netBalance,
                receivable: vm.totalReceivable,
                payable: vm.totalPayable,
                personCount: vm.persons.count
            )
            .padding(.horizontal, Spacing.xl)
            .scaleEffect(contentAppeared ? 1 : 0.92)
            .opacity(contentAppeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1), value: contentAppeared)

            // Rate ticker
            if let rates = vm.exchangeRates {
                rateScrollView(rates)
                    .padding(.top, Spacing.l)
                    .padding(.horizontal, Spacing.xl)
                    .entrance(.up, delay: 0.2)
            }

            Spacer().frame(height: Spacing.xl)
        }
    }

    // MARK: - Rate Ticker (Horizontal Scroll)

    private func rateScrollView(_ rates: ExchangeRateSnapshot) -> some View {
        let items: [(emoji: String, code: String, rate: Decimal?)] = [
            ("🇺🇸", "USD", rates.usdRate),
            ("🇪🇺", "EUR", rates.eurRate),
            ("🥇", "GAU", rates.goldRate),

        ].filter { $0.rate != nil }

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                ForEach(items, id: \.code) { item in
                    NavigationLink { RatesView() } label: {
                        VStack(spacing: Spacing.xxs) {
                            Text(item.emoji)
                                .font(.title3)
                            Text(item.code)
                                .font(Typography.font(for: .label))
                                .foregroundStyle(ColorTokens.textTertiary)
                            Text(item.rate!, format: .number.precision(.fractionLength(2)))
                                .font(Typography.font(for: .amountSmall))
                                .foregroundStyle(ColorTokens.textPrimary)
                                .contentTransition(.numericText())
                        }
                        .padding(.horizontal, Spacing.l)
                        .padding(.vertical, Spacing.s)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                .fill(ColorTokens.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                .stroke(ColorTokens.border, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.xxxs)
        }
    }

    // MARK: - Content Section

    private func contentSection(_ vm: DashboardViewModel) -> some View {
        VStack(spacing: Spacing.l) {
            // Quick Action Strip (horizontal pills)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s) {
                    NavigationLink(destination: {
                        PeopleListView(personRepo: personRepo, debtRepo: debtRepo, balanceRepo: balanceRepo, paymentRepo: paymentRepo)
                    }) {
                        ActionPill(
                            icon: "person.2.fill",
                            title: String(localized: "dashboard.action.people"),
                            color: ColorTokens.chartBlue
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: {
                        ChartsHostView(
                            totalReceivable: vm.totalReceivable,
                            totalPayable: vm.totalPayable,
                            netBalance: vm.netBalance,
                            monthlyTrendData: vm.monthlyTrendData,
                            pendingCount: vm.pendingDebtCount,
                            paidCount: vm.paidDebtCount,
                            archivedCount: vm.archivedDebtCount,
                            currencyDistribution: vm.currencyDistribution,
                            upcomingItems: vm.upcomingChartItems,
                            personCount: vm.persons.count,
                            personBalances: vm.personBalances,
                            paidAmount: vm.paidAmount,
                            pendingAmount: vm.pendingAmount
                        )
                    }) {
                        ActionPill(
                            icon: "chart.pie.fill",
                            title: String(localized: "dashboard.action.charts"),
                            color: ColorTokens.chartPurple
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: { RatesView() }) {
                        ActionPill(
                            icon: "dollarsign.circle.fill",
                            title: String(localized: "rates.title"),
                            color: ColorTokens.chartOrange
                        )
                    }
                    .buttonStyle(.plain)

                    ActionPill(
                        icon: "plus.circle.fill",
                        title: String(localized: "dashboard.action.add"),
                        color: ColorTokens.positive
                    ) {
                        HapticFeedback.impact(.light)
                        showAdd = true
                    }
                }
                .padding(.horizontal, Spacing.xl)
            }
            .entrance(.up, delay: 0.1)

            // Stats row
            if vm.monthlyStats.totalPersonCount > 0 {
                HStack(spacing: Spacing.m) {
                    StatCard(value: "\\(vm.monthlyStats.totalPersonCount)", label: String(localized: "dashboard.month.people"), icon: "person.2", color: ColorTokens.chartBlue)
                        .entrance(.scale, delay: 0.15)
                    StatCard(value: "\\(vm.monthlyStats.pendingDebtCount)", label: String(localized: "dashboard.month.pending"), icon: "clock", color: ColorTokens.chartOrange)
                        .entrance(.scale, delay: 0.2)
                    StatCard(value: "\\(vm.monthlyStats.activePersonCount)", label: String(localized: "dashboard.month.active"), icon: "bolt", color: ColorTokens.positive)
                        .entrance(.scale, delay: 0.25)
                }
                .padding(.horizontal, Spacing.xl)
            }

            // Monthly Trend (Mini Sparkline)
            if vm.monthlyTrendData.count >= 2 {
                GlassCard(
                    title: String(localized: "dashboard.monthly.trend"),
                    subtitle: String(localized: "dashboard.monthly.trend.desc"),
                    icon: "chart.line.uptrend.xyaxis",
                    accentColor: ColorTokens.accent
                ) {
                    let values = vm.monthlyTrendData.map { CGFloat(truncating: $0.net as NSNumber) }
                    MiniSparkline(data: values, lineColor: ColorTokens.accent)
                        .frame(height: 50)
                        .padding(.top, Spacing.s)

                    // Month labels
                    HStack {
                        ForEach(vm.monthlyTrendData, id: \.month) { item in
                            Text(item.month)
                                .font(Typography.font(for: .label))
                                .foregroundStyle(ColorTokens.textTertiary)
                            if item.month != vm.monthlyTrendData.last?.month {
                                Spacer()
                            }
                        }
                    }
                    .padding(.top, Spacing.xs)
                }
                .padding(.horizontal, Spacing.xl)
                .entrance(.up, delay: 0.2)
            }

            // Top People Leaderboard
            if !vm.personBalances.isEmpty {
                let top5 = vm.personBalances
                    .sorted { abs($0.balance) > abs($1.balance) }
                    .prefix(5)

                GlassCard(
                    title: String(localized: "dashboard.top.title"),
                    subtitle: String(localized: "dashboard.top.desc"),
                    icon: "person.3.fill",
                    accentColor: ColorTokens.chartOrange
                ) {
                    VStack(spacing: 0) {
                        ForEach(Array(top5.enumerated()), id: \.element.name) { i, item in
                            LeaderboardRow(
                                rank: i + 1,
                                name: item.name,
                                amount: abs(item.balance),
                                isReceivable: item.balance > 0
                            )
                            .entrance(.leading, delay: Double(i) * 0.06, duration: 0.35)
                            if i < top5.count - 1 {
                                Divider()
                                    .overlay(ColorTokens.border)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .entrance(.up, delay: 0.3)
            }

            // Upcoming
            if !vm.upcomingItems.isEmpty {
                GlassCard(
                    title: String(localized: "dashboard.upcoming.title"),
                    icon: "calendar.badge.clock",
                    accentColor: ColorTokens.chartOrange
                ) {
                    VStack(spacing: 0) {
                        ForEach(Array(vm.upcomingItems.enumerated()), id: \.element.id) { i, item in
                            UpcomingRow(item: item)
                                .entrance(.leading, delay: Double(i) * 0.05, duration: 0.4)
                            if i < vm.upcomingItems.count - 1 {
                                Divider()
                                    .overlay(ColorTokens.border)
                                    .padding(.leading, 56)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .entrance(.up, delay: 0.35)
            }

            // Recent Activity
            if !vm.recentActivity.isEmpty {
                GlassCard(
                    title: String(localized: "dashboard.recent.title"),
                    icon: "clock.arrow.circlepath",
                    accentColor: ColorTokens.accent
                ) {
                    VStack(spacing: 0) {
                        ForEach(Array(vm.recentActivity.enumerated()), id: \.element.id) { i, item in
                            ActivityRow(item: item)
                                .entrance(.leading, delay: Double(i) * 0.04, duration: 0.4)
                            if i < vm.recentActivity.count - 1 {
                                Divider()
                                    .overlay(ColorTokens.border)
                                    .padding(.leading, 40)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .entrance(.up, delay: 0.4)
            }

            // Currency Distribution
            if !vm.currencyDistribution.isEmpty {
                GlassCard(
                    title: String(localized: "dashboard.currency.title"),
                    icon: "chart.bar.xaxis",
                    accentColor: ColorTokens.chartTeal
                ) {
                    CurrencyBarChart(distribution: vm.currencyDistribution)
                        .padding(.vertical, Spacing.s)
                }
                .padding(.horizontal, Spacing.xl)
                .entrance(.up, delay: 0.45)
            }

            Spacer().frame(height: Spacing.xxxl)
        }
        .padding(.vertical, Spacing.l)
        .background(ColorTokens.background)
    }

    // MARK: - Helpers

    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return String(localized: "dashboard.greeting.morning")
        case 12..<18: return String(localized: "dashboard.greeting.afternoon")
        default: return String(localized: "dashboard.greeting.evening")
        }
    }
}

// MARK: - Upcoming Row

private struct UpcomingRow: View {
    let item: (id: UUID, person: Person, amount: Decimal, dueDate: Date?)

    var body: some View {
        HStack(spacing: Spacing.m) {
            AvatarView(name: item.person.name, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.person.name)
                    .font(Typography.font(for: .bodyEmphasis))
                    .foregroundStyle(ColorTokens.textPrimary)
                if let due = item.dueDate {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))
                        Text(due, format: .dateTime.day().month(.abbreviated))
                    }
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(ColorTokens.textTertiary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.amount.formatted())
                    .font(Typography.font(for: .amount))
                    .foregroundStyle(ColorTokens.positive)
                    .contentTransition(.numericText())
                if let date = item.dueDate, isOverdue(date) {
                    Text(String(localized: "dashboard.upcoming.overdue"))
                        .font(Typography.font(for: .label))
                        .foregroundStyle(ColorTokens.negative)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxxs)
                        .background(ColorTokens.negative.opacity(0.12), in: .capsule)
                }
            }
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }

    private func isOverdue(_ date: Date) -> Bool {
        Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
    }
}

// MARK: - Activity Row

private struct ActivityRow: View {
    let item: ActivityItem

    var body: some View {
        HStack(spacing: Spacing.m) {
            ZStack {
                Circle()
                    .fill(item.direction == .receivable
                        ? ColorTokens.positive.opacity(0.15)
                        : ColorTokens.negative.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: item.direction == .receivable
                    ? "arrow.down.left"
                    : "arrow.up.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(item.direction == .receivable
                        ? ColorTokens.positive
                        : ColorTokens.negative)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.personName)
                    .font(Typography.font(for: .bodyEmphasis))
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(item.date, format: .relative(presentation: .named))
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(ColorTokens.textTertiary)
            }
            Spacer()
            Text(item.direction == .receivable
                 ? "+\(item.kind.format(item.amount))"
                 : "-\(item.kind.format(item.amount))")
                .font(Typography.font(for: .amount))
                .foregroundStyle(item.direction == .receivable
                    ? ColorTokens.positive : ColorTokens.negative)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }
}

// MARK: - Currency Bar Chart

private struct CurrencyBarChart: View {
    let distribution: [(kind: CurrencyKind, total: Decimal)]
    private let maxTotal: Decimal

    init(distribution: [(kind: CurrencyKind, total: Decimal)]) {
        self.distribution = distribution
        self.maxTotal = distribution.map(\.total).max() ?? 1
    }

    var body: some View {
        VStack(spacing: Spacing.s) {
            ForEach(distribution, id: \.kind) { item in
                HStack(spacing: Spacing.m) {
                    Text(item.kind.rawValue)
                        .font(Typography.font(for: .label))
                        .foregroundStyle(ColorTokens.textSecondary)
                        .frame(width: 40, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: Radius.xs)
                                .fill(ColorTokens.border)
                                .frame(height: 10)
                            RoundedRectangle(cornerRadius: Radius.xs)
                                .fill(barColor(for: item.kind))
                                .frame(width: max(geo.size.width * CGFloat(NSDecimalNumber(decimal: item.total / maxTotal).doubleValue), 4), height: 10)
                                .shadow(color: barColor(for: item.kind).opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    .frame(height: 10)

                    Text(item.total.formatted())
                        .font(Typography.font(for: .amountSmall))
                        .foregroundStyle(ColorTokens.textPrimary)
                        .frame(width: 80, alignment: .trailing)
                        .contentTransition(.numericText())
                }
            }
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
}

// Preview disabled: requires repository injection.
