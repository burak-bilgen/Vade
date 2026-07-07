import SwiftUI
import DesignSystem
import Domain
import Core
import Observability
import Networking

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
        ZStack {
            FinanceBackgroundAnimation()
                .ignoresSafeArea()
            ColorTokens.background.opacity(0.12).ignoresSafeArea()

            Group {
                if viewModel == nil {
                    DashboardSkeleton()
                        .entrance(.fade)
                } else if let vm = viewModel {
                    content(vm)
                }
            }
        }
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
        VStack(spacing: 0) {
            if !NetworkMonitor.shared.isConnected {
                offlineBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            ScrollView {
                VStack(spacing: 0) {
                    headerSection(vm)
                    contentSection(vm)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: NetworkMonitor.shared.isConnected)
    }

    private var offlineBanner: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(ColorTokens.warning)
            Text(LocalizedStringKey("dashboard.offline.message"))
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textSecondary)
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, 10)
        .background(ColorTokens.warning.opacity(0.08))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(ColorTokens.warning.opacity(0.18)),
            alignment: .bottom
        )
    }

    private func headerSection(_ vm: DashboardViewModel) -> some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 72)

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeGreeting)
                        .font(Typography.font(for: .title))
                        .foregroundStyle(ColorTokens.textPrimary)
                }
                Spacer()
                HStack(spacing: Spacing.m) {
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
                            .foregroundStyle(ColorTokens.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(ColorTokens.surface))
                            .overlay(Circle().stroke(ColorTokens.border, lineWidth: 0.5))
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
            .padding(.bottom, Spacing.xxl)
            .entrance(.up, delay: 0.05)

            PremiumBalanceCard(
                netAmount: vm.netBalance,
                receivable: vm.totalReceivable,
                payable: vm.totalPayable,
                personCount: vm.persons.count,
                lastUpdate: vm.exchangeRates?.lastUpdate
            )
            .padding(.horizontal, Spacing.xl)
            .scaleEffect(contentAppeared ? 1 : 0.9)
            .opacity(contentAppeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1), value: contentAppeared)

            if let rates = vm.exchangeRates {
                rateScrollView(rates)
                    .padding(.top, Spacing.m)
                    .entrance(.up, delay: 0.2)
            }
        }
    }

    private func rateScrollView(_ rates: ExchangeRateSnapshot) -> some View {
        var tempItems: [(emoji: String, code: String, rate: Decimal?)] = [
            ("🇺🇸", "USD", rates.usdRate),
            ("🇪🇺", "EUR", rates.eurRate),
            ("🇬🇧", "GBP", rates.gbpRate)
        ]
        
        if let gold = rates.goldRate {
            let gramItem: (emoji: String, code: String, rate: Decimal?) = ("🟡", "GRAM", gold)
            let qtrItem: (emoji: String, code: String, rate: Decimal?) = ("🪙", "ÇEYREK", gold * Decimal(1.75))
            tempItems.append(gramItem)
            tempItems.append(qtrItem)
        }
        
        let otherItems: [(emoji: String, code: String, rate: Decimal?)] = [
            ("🇨🇭", "CHF", rates.chfRate),
            ("🇯🇵", "JPY", rates.jpyRate)
        ]
        tempItems.append(contentsOf: otherItems)
        
        let items = tempItems

        return VStack(spacing: Spacing.xxs) {
            HStack {
                Text(String(localized: "rates.title"))
                    .font(Typography.font(for: .label))
                    .foregroundStyle(ColorTokens.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                if let lastUpdate = rates.lastUpdate {
                    Text(lastUpdate, format: .dateTime.hour().minute().day().month(.abbreviated))
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textTertiary)
                }
            }
            .padding(.horizontal, Spacing.xl)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s) {
                    ForEach(items, id: \.code) { item in
                        NavigationLink { RatesView() } label: {
                            RateTile(flag: item.emoji, code: item.code, rate: item.rate)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.xl)
            }
        }
    }

    private func contentSection(_ vm: DashboardViewModel) -> some View {
        VStack(spacing: Spacing.m) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s) {
                    NavigationLink(destination: {
                        PeopleListView(personRepo: personRepo, debtRepo: debtRepo, balanceRepo: balanceRepo, paymentRepo: paymentRepo)
                    }) {
                        ActionPill(icon: "person.2.fill", title: String(localized: "dashboard.action.people"), color: ColorTokens.chartBlue)
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: {
                        ChartsHostView(
                            totalReceivable: vm.totalReceivable, totalPayable: vm.totalPayable,
                            netBalance: vm.netBalance, monthlyTrendData: vm.monthlyTrendData,
                            pendingCount: vm.pendingDebtCount, paidCount: vm.paidDebtCount,
                            archivedCount: vm.archivedDebtCount, currencyDistribution: vm.currencyDistribution,
                            upcomingItems: vm.upcomingChartItems, personCount: vm.persons.count,
                            personBalances: vm.personBalances, paidAmount: vm.paidAmount, pendingAmount: vm.pendingAmount
                        )
                    }) {
                        ActionPill(icon: "chart.pie.fill", title: String(localized: "dashboard.action.charts"), color: ColorTokens.chartPurple)
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: { RatesView() }) {
                        ActionPill(icon: "dollarsign.circle.fill", title: String(localized: "rates.title"), color: ColorTokens.chartOrange)
                    }
                    .buttonStyle(.plain)

                    ActionPill(icon: "plus.circle.fill", title: String(localized: "dashboard.action.add"), color: ColorTokens.positive) {
                        HapticFeedback.impact(.light)
                        showAdd = true
                    }
                }
                .padding(.horizontal, Spacing.xl)
            }
            .entrance(.up, delay: 0.1)

            if vm.monthlyStats.totalPersonCount > 0 {
                HStack(spacing: Spacing.m) {
                    StatCard(value: "\(vm.monthlyStats.totalPersonCount)", label: String(localized: "dashboard.month.people"), icon: "person.2", color: ColorTokens.chartBlue)
                        .entrance(.scale, delay: 0.15)
                    StatCard(value: "\(vm.monthlyStats.pendingDebtCount)", label: String(localized: "dashboard.month.pending"), icon: "clock", color: ColorTokens.chartOrange)
                        .entrance(.scale, delay: 0.2)
                    StatCard(value: "\(vm.monthlyStats.activePersonCount)", label: String(localized: "dashboard.month.active"), icon: "bolt", color: ColorTokens.positive)
                        .entrance(.scale, delay: 0.25)
                }
                .padding(.horizontal, Spacing.xl)
            }

            if vm.monthlyTrendData.count >= 2 {
                GlassCard(
                    title: String(localized: "dashboard.monthly.trend"),
                    subtitle: String(localized: "dashboard.monthly.trend.desc"),
                    icon: "chart.line.uptrend.xyaxis",
                    accentColor: ColorTokens.accent
                ) {
                    let values = vm.monthlyTrendData.map { CGFloat(truncating: $0.net as NSNumber) }
                    MiniSparkline(data: values, lineColor: ColorTokens.accent)
                        .frame(height: 44)
                        .padding(.top, Spacing.s)
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
                    .padding(.top, Spacing.xxs)
                }
                .padding(.horizontal, Spacing.xl)
                .entrance(.up, delay: 0.2)
            }

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
                            LeaderboardRow(rank: i + 1, name: item.name, amount: abs(item.balance), isReceivable: item.balance > 0)
                                .entrance(.leading, delay: Double(i) * 0.06, duration: 0.35)
                            if i < top5.count - 1 { DashedDivider() }
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .entrance(.up, delay: 0.3)
            }

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
                                DashedDivider().padding(.leading, 52)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .entrance(.up, delay: 0.35)
            }

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
                                DashedDivider().padding(.leading, 36)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .entrance(.up, delay: 0.4)
            }

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
        .padding(.vertical, Spacing.m)
        .background(ColorTokens.background)
    }

    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return String(localized: "dashboard.greeting.morning")
        case 12..<18: return String(localized: "dashboard.greeting.afternoon")
        default: return String(localized: "dashboard.greeting.evening")
        }
    }
}

private struct UpcomingRow: View {
    let item: (id: UUID, person: Person, amount: Decimal, dueDate: Date?)

    var body: some View {
        HStack(spacing: Spacing.m) {
            AvatarView(name: item.person.name, size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.person.name)
                    .font(Typography.font(for: .bodyEmphasis))
                    .foregroundStyle(ColorTokens.textPrimary)
                if let due = item.dueDate {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "calendar").font(.system(size: 9))
                        Text(due, format: .dateTime.day().month(.abbreviated))
                    }
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(ColorTokens.textTertiary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.amount.formatted())
                    .font(Typography.font(for: .amountSmall))
                    .foregroundStyle(ColorTokens.positive)
                    .contentTransition(.numericText())
                if let date = item.dueDate, isOverdue(date) {
                    Text(String(localized: "dashboard.upcoming.overdue"))
                        .font(Typography.font(for: .label))
                        .foregroundStyle(ColorTokens.warning)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, 1)
                        .background(ColorTokens.warning.opacity(0.12), in: .capsule)
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

private struct ActivityRow: View {
    let item: ActivityItem

    var body: some View {
        HStack(spacing: Spacing.m) {
            ZStack {
                Circle()
                    .fill(item.direction == .receivable ? ColorTokens.positiveLight : ColorTokens.negativeLight)
                    .frame(width: 32, height: 32)
                Image(systemName: item.direction == .receivable ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(item.direction == .receivable ? ColorTokens.positive : ColorTokens.negative)
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
            Text(item.direction == .receivable ? "+\(item.kind.format(item.amount))" : "-\(item.kind.format(item.amount))")
                .font(Typography.font(for: .amountSmall))
                .foregroundStyle(item.direction == .receivable ? ColorTokens.positive : ColorTokens.negative)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }
}

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
                        .frame(width: 36, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: Radius.xs)
                                .fill(ColorTokens.border)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: Radius.xs)
                                .fill(barColor(for: item.kind))
                                .frame(width: max(geo.size.width * CGFloat(NSDecimalNumber(decimal: item.total / maxTotal).doubleValue), 4), height: 8)
                        }
                    }
                    .frame(height: 8)
                    Text(item.total.formatted())
                        .font(Typography.font(for: .amountSmall))
                        .foregroundStyle(ColorTokens.textPrimary)
                        .frame(width: 76, alignment: .trailing)
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
