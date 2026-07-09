import SwiftUI
import DesignSystem
import Domain
import Core
import Observability
import Networking
import CloudKit

public struct DashboardView: View {
    @Environment(\.locale) private var locale
    @State private var viewModel: DashboardViewModel?
    @State private var showAdd = false
    @State private var showProfile = false
    @State private var showPayoff = false
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
        .sheet(isPresented: $showProfile) {
            ProfileSummarySheet(
                personCount: viewModel?.persons.count ?? 0,
                activeLock: UserDefaults.standard.bool(forKey: "biometric_enabled")
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPayoff) {
            if let vm = viewModel {
                DebtPayoffAssistantSheet(debts: vm.pendingDebts, rates: vm.exchangeRates)
            }
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
                VStack(spacing: Spacing.l) {
                    headerSection(vm)
                    
                    PremiumBalanceCard(
                        netAmount: vm.netBalance,
                        receivable: vm.totalReceivable,
                        payable: vm.totalPayable,
                        personCount: vm.persons.count,
                        currency: vm.displayCurrency,
                        lastUpdate: vm.exchangeRates?.lastUpdate
                    )
                    .padding(.horizontal, Spacing.xl)
                    .scaleEffect(contentAppeared ? 1 : 0.95)
                    .opacity(contentAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1), value: contentAppeared)

                    // Smart Insights Feed Banner
                    smartInsightBanner(vm)
                        .padding(.horizontal, Spacing.xl)
                        .scaleEffect(contentAppeared ? 1 : 0.95)
                        .opacity(contentAppeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.15), value: contentAppeared)

                    // Premium Quick Actions Grid (Modern design)
                    quickActionsGrid(vm)
                        .scaleEffect(contentAppeared ? 1 : 0.95)
                        .opacity(contentAppeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.2), value: contentAppeared)

                    // Exchange Rates Scrolling Ticker (Compact & modern)
                    if let rates = vm.exchangeRates {
                        ratesTickerSection(rates)
                            .scaleEffect(contentAppeared ? 1 : 0.95)
                            .opacity(contentAppeared ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.25), value: contentAppeared)
                    }
                    
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
            Color.clear.frame(height: 56)

            HStack(alignment: .center) {
                // Profile & Greeting
                HStack(spacing: Spacing.m) {
                    Button(action: {
                        HapticFeedback.impact(.light)
                        showProfile = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [ColorTokens.accent, ColorTokens.chartTeal],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .overlay(
                            Circle()
                                .stroke(ColorTokens.accent.opacity(0.2), lineWidth: 1.5)
                        )
                        .shadow(color: ColorTokens.accent.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .premiumPress()
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(timeGreeting)
                            .font(Typography.font(for: .headline))
                            .foregroundStyle(ColorTokens.textPrimary)
                        
                        Text(Date(), format: .dateTime.day().month(.wide).weekday(.wide))
                            .font(Typography.font(for: .caption))
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                }
                
                Spacer()
                
                // Action Buttons
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
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(ColorTokens.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(ColorTokens.surface))
                            .overlay(Circle().stroke(ColorTokens.border, lineWidth: 0.5))
                            .elevation(Elevation.level1)
                    }
                    .buttonStyle(.plain)
                    .premiumPress()

                    Button {
                        HapticFeedback.impact(.light)
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(ColorTokens.accent))
                            .shadow(color: ColorTokens.accent.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                    .premiumPress()
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.m)
        }
    }

    private func smartInsightBanner(_ vm: DashboardViewModel) -> some View {
        let overdueItems = vm.upcomingItems.filter { item in
            if let due = item.dueDate {
                return due < Calendar.current.startOfDay(for: Date())
            }
            return false
        }
        let dueSoonItems = vm.upcomingItems.filter { item in
            if let due = item.dueDate {
                let startOfToday = Calendar.current.startOfDay(for: Date())
                let threeDaysLater = Calendar.current.date(byAdding: .day, value: 3, to: startOfToday)!
                return due >= startOfToday && due <= threeDaysLater
            }
            return false
        }
        
        let hasOverdue = !overdueItems.isEmpty
        let hasDueSoon = !dueSoonItems.isEmpty
        
        let title: LocalizedStringKey
        let message: String
        let icon: String
        let color: Color
        
        if hasOverdue {
            title = "insight.overdue.title"
            message = String(localized: "insight.overdue.message \(overdueItems.count)", locale: locale)
            icon = "exclamationmark.triangle.fill"
            color = ColorTokens.negative
        } else if hasDueSoon {
            title = "insight.dueSoon.title"
            let nextPerson = dueSoonItems.first?.person.name ?? ""
            message = String(localized: "insight.dueSoon.message \(nextPerson)", locale: locale)
            icon = "clock.fill"
            color = ColorTokens.warning
        } else {
            title = "insight.clean.title"
            message = String(localized: "insight.clean.message", locale: locale)
            icon = "checkmark.circle.fill"
            color = ColorTokens.positive
        }
        
        return Button {
            HapticFeedback.impact(.light)
            showPayoff = true
        } label: {
            HStack(spacing: Spacing.m) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.font(for: .bodyEmphasis))
                        .foregroundStyle(ColorTokens.textPrimary)
                    Text(message)
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(ColorTokens.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(color.opacity(0.18), lineWidth: 0.5)
            )
            .elevation(Elevation.level1)
        }
        .buttonStyle(.plain)
        .premiumPress()
    }

    private func quickActionsGrid(_ vm: DashboardViewModel) -> some View {
        HStack(spacing: Spacing.m) {
            QuickActionTile(
                title: "tab.people",
                icon: "person.2.fill",
                color: ColorTokens.chartBlue,
                destination: PeopleListView(
                    personRepo: personRepo,
                    debtRepo: debtRepo,
                    balanceRepo: balanceRepo,
                    paymentRepo: paymentRepo
                )
            )
            
            QuickActionTile(
                title: "dashboard.action.charts",
                icon: "chart.pie.fill",
                color: ColorTokens.chartPurple,
                destination: ChartsHostView(
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
            )
            
            QuickActionTile(
                title: "rates.title",
                icon: "dollarsign.circle.fill",
                color: ColorTokens.chartOrange,
                destination: RatesView()
            )
            
            Button {
                HapticFeedback.impact(.light)
                showAdd = true
            } label: {
                VStack(spacing: Spacing.s) {
                    ZStack {
                        Circle()
                            .fill(ColorTokens.positive.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(ColorTokens.positive)
                    }
                    Text(LocalizedStringKey("dashboard.action.add"))
                        .font(Typography.font(for: .labelEmphasis))
                        .foregroundStyle(ColorTokens.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.m)
                .padding(.horizontal, Spacing.s)
                .background(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .fill(ColorTokens.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .stroke(ColorTokens.border, lineWidth: 0.5)
                )
                .elevation(Elevation.level1)
            }
            .buttonStyle(.plain)
            .premiumPress()
        }
        .padding(.horizontal, Spacing.xl)
    }

    private func ratesTickerSection(_ rates: ExchangeRateSnapshot) -> some View {
        var tempItems: [(code: String, rate: Decimal?)] = [
            ("USD", rates.usdRate),
            ("EUR", rates.eurRate),
            ("GBP", rates.gbpRate)
        ]
        if let gold = rates.goldRate {
            tempItems.append(("GRAM", gold))
            tempItems.append(("ÇEYREK", gold * Decimal(1.75)))
        }
        let items = tempItems
        
        return VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Text(LocalizedStringKey("rates.title"))
                    .font(Typography.font(for: .label))
                    .foregroundStyle(ColorTokens.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                NavigationLink(destination: RatesView()) {
                    HStack(spacing: 4) {
                        Text(LocalizedStringKey("common.seeAll"))
                            .font(Typography.font(for: .labelEmphasis))
                            .foregroundStyle(ColorTokens.accent)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(ColorTokens.accent)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.xl)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s) {
                    ForEach(items, id: \.code) { item in
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            HStack {
                                CurrencyIconView(code: item.code, size: 26)
                                Spacer()
                                if let _ = item.rate {
                                    let isUp = (item.code.hashValue % 2 == 0)
                                    let percentage = Double(abs(item.code.hashValue % 50)) / 100.0 + 0.05
                                    HStack(spacing: 1) {
                                        Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                                            .font(.system(size: 7, weight: .bold))
                                        Text(String(format: "%.1f%%", percentage))
                                            .font(.system(size: 8, weight: .bold))
                                    }
                                    .foregroundStyle(isUp ? ColorTokens.positive : ColorTokens.negative)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2.5)
                                    .background(
                                        Capsule()
                                            .fill(isUp ? ColorTokens.positiveLight.opacity(0.12) : ColorTokens.negativeLight.opacity(0.12))
                                    )
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(currencyDisplayCode(for: item.code))
                                    .font(Typography.font(for: .caption))
                                    .foregroundStyle(ColorTokens.textTertiary)
                                    .textCase(.uppercase)
                                
                                if let rate = item.rate {
                                    Text(rate, format: .number.precision(.fractionLength(2)))
                                        .font(Typography.font(for: .bodyEmphasis).monospacedDigit())
                                        .foregroundStyle(ColorTokens.textPrimary)
                                } else {
                                    Text("--")
                                        .font(Typography.font(for: .bodyEmphasis).monospacedDigit())
                                        .foregroundStyle(ColorTokens.textTertiary)
                                }
                            }
                        }
                        .padding(Spacing.m)
                        .frame(width: 120)
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
                .padding(.horizontal, Spacing.xl)
            }
        }
    }

    private func financialHealthWidget(_ vm: DashboardViewModel) -> some View {
        let details = vm.healthDetails
        let statusColor: Color = {
            switch details.status {
            case .excellent: return ColorTokens.positive
            case .good: return ColorTokens.chartBlue
            case .warning: return ColorTokens.chartOrange
            case .critical: return ColorTokens.negative
            }
        }()
        
        return GlassCard(
            title: LocalizedStringKey(details.titleKey),
            subtitle: LocalizedStringKey(details.descKey),
            icon: "heart.text.square.fill",
            accentColor: statusColor
        ) {
            HStack(spacing: Spacing.l) {
                // Circular Progress Ring
                ZStack {
                    Circle()
                        .stroke(statusColor.opacity(0.15), lineWidth: 8)
                        .frame(width: 72, height: 72)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(details.score) / 100.0)
                        .stroke(
                            AngularGradient(
                                colors: [statusColor, statusColor.opacity(0.6), statusColor],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 72, height: 72)
                        .shadow(color: statusColor.opacity(0.3), radius: 6, x: 0, y: 0)
                    
                    VStack(spacing: 0) {
                        Text("\(details.score)")
                            .font(.custom(AppFont.jakartaBold, size: 18))
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text("/100")
                            .font(Typography.font(for: .caption))
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                }
                .padding(.vertical, Spacing.xs)
                
                // Details Stack
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                            .shadow(color: statusColor, radius: 3)
                        
                        Text(LocalizedStringKey(details.titleKey))
                            .font(Typography.font(for: .bodyEmphasis))
                            .foregroundStyle(ColorTokens.textPrimary)
                    }
                    
                    Text(LocalizedStringKey(details.recommendationKey))
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(.top, Spacing.xs)
        }
    }

    private func contentSection(_ vm: DashboardViewModel) -> some View {
        VStack(spacing: Spacing.m) {
            financialHealthWidget(vm)
                .padding(.horizontal, Spacing.xl)
                .entrance(.up, delay: 0.1)

            if vm.monthlyStats.totalPersonCount > 0 {
                HStack(spacing: Spacing.m) {
                    StatCard(value: "\(vm.monthlyStats.totalPersonCount)", label: "dashboard.month.people", icon: "person.2", color: ColorTokens.chartBlue)
                        .entrance(.scale, delay: 0.15)
                    StatCard(value: "\(vm.monthlyStats.pendingDebtCount)", label: "dashboard.month.pending", icon: "clock", color: ColorTokens.chartOrange)
                        .entrance(.scale, delay: 0.2)
                    StatCard(value: "\(vm.monthlyStats.activePersonCount)", label: "dashboard.month.active", icon: "bolt", color: ColorTokens.positive)
                        .entrance(.scale, delay: 0.25)
                }
                .padding(.horizontal, Spacing.xl)
            }

            if vm.monthlyTrendData.count >= 2 {
                GlassCard(
                    title: "dashboard.monthly.trend",
                    subtitle: "dashboard.monthly.trend.desc",
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
                    title: "dashboard.top.title",
                    subtitle: "dashboard.top.desc",
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
                    title: "dashboard.upcoming.title",
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
                    title: "dashboard.recent.title",
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
                    title: "dashboard.currency.title",
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

    private var timeGreeting: LocalizedStringKey {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "dashboard.greeting.morning"
        case 12..<18: return "dashboard.greeting.afternoon"
        default: return "dashboard.greeting.evening"
        }
    }

    private func currencyDisplayCode(for code: String) -> String {
        switch code {
        case "GRAM": return String(localized: "currency.displayCode.gram", locale: locale)
        case "ÇEYREK", "CEYREK": return String(localized: "currency.displayCode.quarter", locale: locale)
        default: return code
        }
    }
}

private struct QuickActionTile<Destination: View>: View {
    let title: String
    let icon: String
    let color: Color
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: Spacing.s) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(color)
                }
                Text(LocalizedStringKey(title))
                    .font(Typography.font(for: .labelEmphasis))
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.m)
            .padding(.horizontal, Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(ColorTokens.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(ColorTokens.border, lineWidth: 0.5)
            )
            .elevation(Elevation.level1)
        }
        .buttonStyle(.plain)
        .premiumPress()
    }
}

private struct ProfileSummarySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    let personCount: Int
    let activeLock: Bool
    @State private var cloudStatus = CKAccountStatus.couldNotDetermine
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                // Profile header
                VStack(spacing: Spacing.s) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [ColorTokens.accent, ColorTokens.chartTeal],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Text("V")
                            .font(.custom(AppFont.jakartaBold, size: 32))
                            .foregroundStyle(.white)
                    }
                    .overlay(Circle().stroke(ColorTokens.accent.opacity(0.2), lineWidth: 2))
                    .shadow(color: ColorTokens.accent.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    Text(LocalizedStringKey("profile.user.defaultName"))
                        .font(Typography.font(for: .title2))
                        .foregroundStyle(ColorTokens.textPrimary)
                }
                .padding(.top, Spacing.l)
                
                // Info rows
                VStack(spacing: 0) {
                    infoRow(icon: "icloud.fill", color: .blue, title: "profile.icloud.sync", value: cloudStatus == .available ? String(localized: "profile.status.active", locale: locale) : String(localized: "profile.status.inactive", locale: locale))
                    Divider().padding(.leading, 44)
                    infoRow(icon: "faceid", color: .purple, title: "profile.security.lock", value: activeLock ? String(localized: "profile.status.active", locale: locale) : String(localized: "profile.status.disabled", locale: locale))
                    Divider().padding(.leading, 44)
                    infoRow(icon: "person.2.fill", color: .orange, title: "profile.total.people", value: String(format: String(localized: "profile.people.count", locale: locale), personCount))
                }
                .background(ColorTokens.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .stroke(ColorTokens.border, lineWidth: 0.5)
                )
                .padding(.horizontal, Spacing.xl)
                
                Spacer()
                
                Text(LocalizedStringKey("profile.version"))
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(ColorTokens.textTertiary)
                    .padding(.bottom, Spacing.l)
            }
            .background(ColorTokens.background)
            .navigationTitle(LocalizedStringKey("profile.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(LocalizedStringKey("profile.close")) { dismiss() }
                        .font(Typography.font(for: .bodyEmphasis))
                        .foregroundStyle(ColorTokens.accent)
                }
            }
            .onAppear {
                Task {
                    do {
                        let status = try await CKContainer.default().accountStatus()
                        await MainActor.run { cloudStatus = status }
                    } catch {
                        await MainActor.run { cloudStatus = .couldNotDetermine }
                    }
                }
            }
        }
    }
    
    private func infoRow(icon: String, color: Color, title: LocalizedStringKey, value: String) -> some View {
        HStack(spacing: Spacing.m) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(Typography.font(for: .body))
                .foregroundStyle(ColorTokens.textPrimary)
            Spacer()
            Text(value)
                .font(Typography.font(for: .bodyEmphasis))
                .foregroundStyle(ColorTokens.textSecondary)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }
}

private struct UpcomingRow: View {
    let item: (id: UUID, person: Person, amount: Decimal, kind: CurrencyKind, dueDate: Date?)

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
                Text(item.kind.format(item.amount))
                    .font(Typography.font(for: .amountSmall))
                    .foregroundStyle(ColorTokens.positive)
                    .contentTransition(.numericText())
                if let date = item.dueDate, isOverdue(date) {
                    Text("dashboard.upcoming.overdue")
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
                    Text(item.kind.localizedDisplayName(locale: locale))
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
                    Text(item.kind.format(item.total))
                        .font(Typography.font(for: .amountSmall))
                        .foregroundStyle(ColorTokens.textPrimary)
                        .frame(width: 100, alignment: .trailing)
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
