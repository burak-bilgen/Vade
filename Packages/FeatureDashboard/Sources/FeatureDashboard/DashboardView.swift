import SwiftUI
import SwiftData
import DesignSystem
import Domain
import Data
import Observability

// MARK: - Dashboard

public struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardViewModel?
    @State private var showAdd = false
    @State private var analytics = AnalyticsService()

    public init() {}

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
            QuickAddSheet { await viewModel?.loadData() }
        }
        .task {
            let vm = DashboardViewModel(modelContext: modelContext)
            viewModel = vm
            await vm.loadData()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                contentAppeared = true
            }
        }
        .refreshable { await viewModel?.loadData() }
    }

    private func content(_ vm: DashboardViewModel) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection(vm)
                contentSection(vm)
            }
        }
    }

    // MARK: - Premium Header with Glassmorphism

    private func headerSection(_ vm: DashboardViewModel) -> some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 60)

            // Greeting + Add button
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeGreeting)
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textTertiary)
                    Text("Vade")
                        .font(Typography.font(for: .title))
                        .foregroundStyle(ColorTokens.textPrimary)
                }
                Spacer()
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(ColorTokens.accent)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(ColorTokens.accent.opacity(0.12)))
                }
                .premiumPress()
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.ml)
            .entrance(.up, delay: 0.1)

            // ✦ Glassmorphism Balance Card ✦
            VStack(spacing: 0) {
                // Top accent ring — animated width
                RoundedRectangle(cornerRadius: 1)
                    .fill(netPositionColor(vm.netBalance))
                    .frame(height: 3)
                    .padding(.horizontal, Spacing.l)
                    .padding(.top, Spacing.s)

                VStack(spacing: Spacing.s) {
                    Text(String(localized: "dashboard.netBalance"))
                        .font(Typography.font(for: .label))
                        .foregroundStyle(ColorTokens.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    Text(vm.netBalance, format: .number.precision(.fractionLength(2)))
                        .font(Typography.font(for: .display))
                        .foregroundStyle(ColorTokens.textPrimary)
                        .contentTransition(.numericText(countsDown: true))
                        .minimumScaleFactor(0.7)
                        .scaleEffect(contentAppeared ? 1 : 0.8)
                        .opacity(contentAppeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: contentAppeared)

                    // Net position indicator
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: vm.netBalance >= 0 ? "arrow.up.forward" : "arrow.down.forward")
                            .font(.system(size: 10, weight: .bold))
                        Text(vm.netBalance >= 0
                            ? String(localized: "dashboard.youAreOwed")
                            : String(localized: "dashboard.youOwe"))
                            .font(Typography.font(for: .caption))
                    }
                    .foregroundStyle(netPositionColor(vm.netBalance))
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.xxs)
                    .background(netPositionColor(vm.netBalance).opacity(0.12), in: .capsule)

                    // Receivable / Payable pills
                    HStack(spacing: Spacing.m) {
                        HStack(spacing: Spacing.xxs) {
                            Circle().fill(ColorTokens.positive).frame(width: 6, height: 6)
                            Text(vm.totalReceivable.formatted())
                                .font(Typography.font(for: .amountSmall))
                                .foregroundStyle(ColorTokens.positive)
                                .contentTransition(.numericText())
                        }
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, Spacing.xxs)
                        .background(ColorTokens.positiveLight.opacity(0.3), in: .capsule)
                        .entrance(.scale, delay: 0.35)

                        HStack(spacing: Spacing.xxs) {
                            Circle().fill(ColorTokens.negative).frame(width: 6, height: 6)
                            Text(vm.totalPayable.formatted())
                                .font(Typography.font(for: .amountSmall))
                                .foregroundStyle(ColorTokens.negative)
                                .contentTransition(.numericText())
                        }
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, Spacing.xxs)
                        .background(ColorTokens.negativeLight.opacity(0.3), in: .capsule)
                        .entrance(.scale, delay: 0.4)
                    }
                }
                .padding(Spacing.xl)
            }
            .glass(GlassStyle.standard)
            .padding(.horizontal, Spacing.xl)
            .entrance(.up, delay: 0.15)

            // Exchange rate ticker
            if let rates = vm.exchangeRates {
                rateTicker(rates)
                    .padding(.top, Spacing.m)
                    .padding(.horizontal, Spacing.xl)
                    .entrance(.up, delay: 0.3)
            }

            Spacer().frame(height: Spacing.xl)
        }
    }

    private func rateTicker(_ rates: ExchangeRateSnapshot) -> some View {
        let items: [(emoji: String, code: String, rate: Decimal?)] = [
            ("🇺🇸", "USD", rates.usdRate),
            ("🇪🇺", "EUR", rates.eurRate),
            ("🥇", "GAU", rates.goldRate),
        ].filter { $0.rate != nil }

        return NavigationLink { RatesView() } label: {
            HStack(spacing: Spacing.l) {
                ForEach(items, id: \.code) { item in
                    HStack(spacing: Spacing.xxs) {
                        Text(item.emoji).font(.caption)
                        Text(item.code)
                            .font(Typography.font(for: .label))
                            .foregroundStyle(ColorTokens.textTertiary)
                        Text(item.rate!, format: .number.precision(.fractionLength(2)))
                            .font(Typography.font(for: .amountSmall))
                            .foregroundStyle(ColorTokens.textPrimary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(ColorTokens.textTertiary)
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(ColorTokens.surface)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content Section

    private func contentSection(_ vm: DashboardViewModel) -> some View {
        VStack(spacing: Spacing.l) {
            // Quick Actions — staggered entrance
            HStack(spacing: Spacing.m) {
                QuickActionButton(
                    icon: "person.2.fill",
                    color: ColorTokens.chartBlue,
                    title: String(localized: "dashboard.action.people"),
                    destination: PeopleListView()
                )
                .entrance(.up, delay: 0.1)
                QuickActionButton(
                    icon: "chart.line.uptrend.xyaxis",
                    color: ColorTokens.chartPurple,
                    title: String(localized: "dashboard.action.charts"),
                    destination: ChartsHostView(
                        totalReceivable: vm.totalReceivable,
                        totalPayable: vm.totalPayable,
                        netBalance: vm.netBalance
                    )
                )
                .entrance(.up, delay: 0.15)
                QuickActionButton(
                    icon: "dollarsign.circle.fill",
                    color: ColorTokens.chartOrange,
                    title: String(localized: "rates.title"),
                    destination: RatesView()
                )
                .entrance(.up, delay: 0.2)
            }
            .padding(.horizontal, Spacing.xl)

            // Stats — staggered entrance
            if vm.monthlyStats.totalPersonCount > 0 {
                HStack(spacing: Spacing.m) {
                    StatCard(value: "\(vm.monthlyStats.totalPersonCount)", label: String(localized: "dashboard.month.people"), icon: "person.2", color: ColorTokens.chartBlue)
                        .entrance(.scale, delay: 0.2)
                    StatCard(value: "\(vm.monthlyStats.pendingDebtCount)", label: String(localized: "dashboard.month.pending"), icon: "clock", color: ColorTokens.chartOrange)
                        .entrance(.scale, delay: 0.25)
                    StatCard(value: "\(vm.monthlyStats.activePersonCount)", label: String(localized: "dashboard.month.active"), icon: "bolt", color: ColorTokens.positive)
                        .entrance(.scale, delay: 0.3)
                }
                .padding(.horizontal, Spacing.xl)
            }

            // Upcoming
            if !vm.upcomingItems.isEmpty {
                SectionCard(title: String(localized: "dashboard.upcoming.title")) {
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
                SectionCard(title: String(localized: "dashboard.recent.title")) {
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
                SectionCard(title: String(localized: "dashboard.currency.title")) {
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

    private func netPositionColor(_ balance: Decimal) -> Color {
        if balance.isEffectivelyZero { return ColorTokens.accent }
        return balance > 0 ? ColorTokens.positive : ColorTokens.negative
    }
}

// MARK: - Quick Action Button

private struct QuickActionButton<Destination: View>: View {
    let icon: String
    let color: Color
    let title: String
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: Spacing.s) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.12), in: .circle)
                Text(title)
                    .font(Typography.font(for: .label))
                    .foregroundStyle(ColorTokens.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.l)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(ColorTokens.surface)
            )
            .elevation(Elevation.level1)
        }
        .buttonStyle(.plain)
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
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
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
        .elevation(Elevation.level1)
    }
}

// MARK: - Section Card

private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)
                .padding(.horizontal, Spacing.l)
                .padding(.top, Spacing.l)
                .padding(.bottom, Spacing.s)

            content
        }
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(ColorTokens.surface)
        )
        .elevation(Elevation.level1)
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
                    Text(due, format: .dateTime.day().month(.abbreviated))
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textTertiary)
                }
            }
            Spacer()
            Text(item.amount.formatted())
                .font(Typography.font(for: .amount))
                .foregroundStyle(ColorTokens.positive)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }
}

// MARK: - Activity Row

private struct ActivityRow: View {
    let item: ActivityItem

    var body: some View {
        HStack(spacing: Spacing.m) {
            Circle()
                .fill(item.direction == .receivable ? ColorTokens.positive : ColorTokens.negative)
                .frame(width: 8, height: 8)
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
                .font(Typography.font(for: .amount))
                .foregroundStyle(item.direction == .receivable ? ColorTokens.positive : ColorTokens.negative)
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

// MARK: - Press Style

/// Subtle scale-down animation on press for buttons.
private struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

private extension View {
    func pressStyle() -> some View {
        buttonStyle(PressStyle())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { DashboardView() }
}
