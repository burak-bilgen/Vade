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

    private let personRepo: FetchPersonsUseCase
    private let debtRepo: FetchDebtsForPersonUseCase
    private let balanceRepo: CalculateBalanceUseCase
    private let rateClient: ExchangeRateProviding

    public init(
        personRepo: FetchPersonsUseCase,
        debtRepo: FetchDebtsForPersonUseCase,
        balanceRepo: CalculateBalanceUseCase,
        rateClient: ExchangeRateProviding = ExchangeRateClient()
    ) {
        self.personRepo = personRepo
        self.debtRepo = debtRepo
        self.balanceRepo = balanceRepo
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

    // MARK: - Header with Gradient Balance Card

    private func headerSection(_ vm: DashboardViewModel) -> some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 60)

            // Greeting + Notification icon
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeGreeting)
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textTertiary)
                    Text(String(localized: "app.name"))
                        .font(Typography.font(for: .title))
                        .foregroundStyle(ColorTokens.textPrimary)
                    Text(String(localized: "app.subtitle"))
                        .font(Typography.font(for: .label))
                        .foregroundStyle(ColorTokens.textTertiary)
                }
                Spacer()
                HStack(spacing: Spacing.m) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(ColorTokens.accent)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(ColorTokens.accent.opacity(0.12)))
                    }
                    .premiumPress()

                    Image(systemName: "bell.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(ColorTokens.textTertiary)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(ColorTokens.surface))
                        .overlay(
                            Circle()
                                .stroke(ColorTokens.border, lineWidth: 0.5)
                        )
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.ml)
            .entrance(.up, delay: 0.1)

            // ✦ Premium Gradient Balance Card ✦
            VStack(spacing: 0) {
                VStack(spacing: Spacing.m) {
                    // Label
                    Text(String(localized: "dashboard.netBalance"))
                        .font(Typography.font(for: .label))
                        .foregroundStyle(.white.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(0.8)

                    // Amount
                    Text(vm.netBalance, format: .number.precision(.fractionLength(2)))
                        .font(Typography.font(for: .display))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText(countsDown: true))
                        .minimumScaleFactor(0.7)
                        .scaleEffect(contentAppeared ? 1 : 0.8)
                        .opacity(contentAppeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: contentAppeared)

                    // Direction pill
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: vm.netBalance >= 0 ? "arrow.up.forward" : "arrow.down.forward")
                            .font(.system(size: 10, weight: .bold))
                        Text(vm.netBalance >= 0
                            ? String(localized: "dashboard.youAreOwed")
                            : String(localized: "dashboard.youOwe"))
                            .font(Typography.font(for: .caption))
                    }
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.xxs)
                    .background(.ultraThinMaterial, in: .capsule)

                    // Receivable / Payable pills
                    HStack(spacing: Spacing.m) {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "arrow.down.left.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(ColorTokens.positive)
                            Text("+" + vm.totalReceivable.formatted())
                                .font(Typography.font(for: .amountSmall))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                        }
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, Spacing.xxs)
                        .background(.ultraThinMaterial, in: .capsule)

                        Text("|")
                            .foregroundStyle(.white.opacity(0.3))

                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "arrow.up.right.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(ColorTokens.negative)
                            Text("-" + vm.totalPayable.formatted())
                                .font(Typography.font(for: .amountSmall))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                        }
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, Spacing.xxs)
                        .background(.ultraThinMaterial, in: .capsule)
                    }
                }
                .padding(Spacing.xxl)
            }
            .background(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .fill(balanceGradient(vm.netBalance))
                    .shadow(color: balanceGlowColor(vm.netBalance).opacity(0.3), radius: 20, x: 0, y: 8)
            )
            .padding(.horizontal, Spacing.xl)
            .entrance(.up, delay: 0.15)

            // Horizontal scroll rate ticker
            if let rates = vm.exchangeRates {
                rateScrollView(rates)
                    .padding(.top, Spacing.m)
                    .padding(.horizontal, Spacing.xl)
                    .entrance(.up, delay: 0.25)
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
            // 2×2 Quick Action Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.m),
                GridItem(.flexible(), spacing: Spacing.m),
            ], spacing: Spacing.m) {
                QuickActionTile(
                    icon: "person.2.fill",
                    gradient: LinearGradient(colors: [ColorTokens.chartBlue, ColorTokens.chartBlue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    title: String(localized: "dashboard.action.people"),
                    subtitle: String(localized: "dashboard.action.people.subtitle \(vm.persons.count)"),
                    destination: PeopleListView()
                )
                .entrance(.up, delay: 0.1)

                QuickActionTile(
                    icon: "chart.pie.fill",
                    gradient: LinearGradient(colors: [ColorTokens.chartPurple, ColorTokens.chartPurple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    title: String(localized: "dashboard.action.charts"),
                    subtitle: String(localized: "dashboard.quickActions.analytics"),
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
                        personCount: vm.persons.count
                    )
                )
                .entrance(.up, delay: 0.15)

                QuickActionTile(
                    icon: "dollarsign.circle.fill",
                    gradient: LinearGradient(colors: [ColorTokens.chartOrange, ColorTokens.chartOrange.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    title: String(localized: "rates.title"),
                    subtitle: String(localized: "dashboard.quickActions.rates"),
                    destination: RatesView()
                )
                .entrance(.up, delay: 0.2)

                QuickActionTile(
                    icon: "plus.circle.fill",
                    gradient: LinearGradient(colors: [ColorTokens.positive, ColorTokens.positive.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    title: String(localized: "dashboard.action.add"),
                    subtitle: String(localized: "dashboard.quickActions.quickAdd"),
                    destination: EmptyView()
                )
                .entrance(.up, delay: 0.25)
                .onTapGesture {
                    HapticFeedback.impact(.light)
                    showAdd = true
                }
            }
            .padding(.horizontal, Spacing.xl)

            // Stats row
            if vm.monthlyStats.totalPersonCount > 0 {
                HStack(spacing: Spacing.m) {
                    StatCard(value: "\\(vm.monthlyStats.totalPersonCount)", label: String(localized: "dashboard.month.people"), icon: "person.2", color: ColorTokens.chartBlue)
                        .entrance(.scale, delay: 0.2)
                    StatCard(value: "\\(vm.monthlyStats.pendingDebtCount)", label: String(localized: "dashboard.month.pending"), icon: "clock", color: ColorTokens.chartOrange)
                        .entrance(.scale, delay: 0.25)
                    StatCard(value: "\\(vm.monthlyStats.activePersonCount)", label: String(localized: "dashboard.month.active"), icon: "bolt", color: ColorTokens.positive)
                        .entrance(.scale, delay: 0.3)
                }
                .padding(.horizontal, Spacing.xl)
            }

            // Upcoming
            if !vm.upcomingItems.isEmpty {
                EnhancedSectionCard(
                    title: String(localized: "dashboard.upcoming.title"),
                    accentColor: ColorTokens.chartOrange,
                    icon: "calendar.badge.clock"
                ) {
                    VStack(spacing: 0) {
                        ForEach(Array(vm.upcomingItems.enumerated()), id: \.element.id) { i, item in
                            UpcomingRow(item: item)
                                .entrance(.leading, delay: Double(i) * 0.06, duration: 0.4)
                            if i < vm.upcomingItems.count - 1 {
                                Divider()
                                    .overlay(ColorTokens.border)
                                    .padding(.leading, 56)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .entrance(.up, delay: 0.3)
            }

            // Recent Activity
            if !vm.recentActivity.isEmpty {
                EnhancedSectionCard(
                    title: String(localized: "dashboard.recent.title"),
                    accentColor: ColorTokens.accent,
                    icon: "clock.arrow.circlepath"
                ) {
                    VStack(spacing: 0) {
                        ForEach(Array(vm.recentActivity.enumerated()), id: \.element.id) { i, item in
                            ActivityRow(item: item)
                                .entrance(.leading, delay: Double(i) * 0.05, duration: 0.4)
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
                EnhancedSectionCard(
                    title: String(localized: "dashboard.currency.title"),
                    accentColor: ColorTokens.chartTeal,
                    icon: "chart.bar.xaxis"
                ) {
                    CurrencyBarChart(distribution: vm.currencyDistribution)
                        .padding(Spacing.l)
                }
                .padding(.horizontal, Spacing.xl)
                .entrance(.up, delay: 0.5)
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

    private func balanceGradient(_ balance: Decimal) -> LinearGradient {
        if balance.isEffectivelyZero {
            return LinearGradient(
                colors: [ColorTokens.accent, ColorTokens.chartPurple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return balance > 0
            ? LinearGradient(
                colors: [ColorTokens.accent, ColorTokens.positive],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            : LinearGradient(
                colors: [ColorTokens.negative, ColorTokens.chartOrange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
    }

    private func balanceGlowColor(_ balance: Decimal) -> Color {
        if balance.isEffectivelyZero { return ColorTokens.chartPurple }
        return balance > 0 ? ColorTokens.positive : ColorTokens.negative
    }
}

// MARK: - Quick Action Tile (Gradient Card)

private struct QuickActionTile<Destination: View>: View {
    let icon: String
    let gradient: LinearGradient
    let title: String
    let subtitle: String
    let destination: Destination

    var body: some View {
        Group {
            if Destination.self == EmptyView.self {
                buttonContent
            } else {
                NavigationLink(destination: destination) {
                    buttonContent
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var buttonContent: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(title)
                .font(Typography.font(for: .bodyEmphasis))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(Typography.font(for: .caption))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(gradient)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .accessibilityLabel("\\(title), \\(subtitle)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(value)
                .font(Typography.font(for: .headline))
                .foregroundStyle(ColorTokens.textPrimary)
                .contentTransition(.numericText())
            Text(label)
                .font(Typography.font(for: .label))
                .foregroundStyle(ColorTokens.textTertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.ml)
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

// MARK: - Enhanced Section Card

private struct EnhancedSectionCard<Content: View>: View {
    let title: String
    let accentColor: Color
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with accent
            HStack(spacing: Spacing.s) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accentColor)
                }

                Text(title)
                    .font(Typography.font(for: .title2))
                    .foregroundStyle(ColorTokens.textPrimary)

                Spacer()
            }
            .padding(.horizontal, Spacing.l)
            .padding(.top, Spacing.l)
            .padding(.bottom, Spacing.s)

            content
        }
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(ColorTokens.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(ColorTokens.border, lineWidth: 0.5)
        )
        .overlay(
            // Left accent bar
            RoundedRectangle(cornerRadius: 1.5)
                .fill(accentColor.opacity(0.5))
                .frame(width: 3)
                .padding(.vertical, Spacing.s),
            alignment: .leading
        )
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
