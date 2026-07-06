import SwiftUI
import SwiftData
import DesignSystem
import Domain
import Data

// MARK: - Dashboard

public struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardViewModel?

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: Spacing.l) {
                if let vm = viewModel {
                    rateTicker(vm)
                    balanceCard(vm)
                    statGrid(vm)
                    actionRow(vm)
                    if !vm.currencyDistribution.isEmpty { currencyRow(vm) }
                    if !vm.recentActivity.isEmpty { activityList(vm) }
                    if !vm.upcomingItems.isEmpty { upcomingList(vm) }
                }
            }
            .padding(.bottom, Spacing.xxxl)
        }
        .background(ColorTokens.background)
        .task {
            let vm = DashboardViewModel(modelContext: modelContext)
            viewModel = vm
            await vm.loadData()
        }
        .refreshable { await viewModel?.loadData() }
    }

    // MARK: Rate Ticker

    private func rateTicker(_ vm: DashboardViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                if let rates = vm.exchangeRates {
                    tick(flag: "🇺🇸", code: "USD", rate: rates.usdRate)
                    tick(flag: "🇪🇺", code: "EUR", rate: rates.eurRate)
                    tick(flag: "🪙", code: "XAU", rate: rates.goldRate)
                }
            }
            .padding(.horizontal, Spacing.l)
        }
        .padding(.top, Spacing.s)
    }

    private func tick(flag: String, code: String, rate: Decimal?) -> some View {
        HStack(spacing: 4) {
            Text(flag)
            Text(code)
                .font(Typography.font(for: .caption))
                .foregroundStyle(.secondary)
            if let rate {
                Text(rate, format: .number.precision(.fractionLength(2)))
                    .font(Typography.font(for: .amount))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(.capsule)
    }

    // MARK: Balance Card

    private func balanceCard(_ vm: DashboardViewModel) -> some View {
        VStack(spacing: Spacing.m) {
            Text(String(localized: "dashboard.netBalance"))
                .font(Typography.font(for: .caption))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(vm.netBalance, format: .number.precision(.fractionLength(2)))
                .font(Typography.font(for: .display))
                .foregroundStyle(balanceColor(vm.netBalance))
                .contentTransition(.numericText())

            Text(vm.netBalance >= 0
                ? String(localized: "dashboard.youAreOwed")
                : String(localized: "dashboard.youOwe")
            )
            .font(Typography.font(for: .caption))
            .foregroundStyle(.secondary)

            Divider().padding(.horizontal, Spacing.xxl)

            HStack(spacing: 0) {
                metric(value: vm.totalReceivable, label: String(localized: "dashboard.receivable"), color: ColorTokens.positive)
                metric(value: vm.totalPayable, label: String(localized: "dashboard.payable"), color: ColorTokens.negative)
            }
        }
        .padding(Spacing.xl)
        .background(ColorTokens.surface, in: .rect(cornerRadius: Radius.xl))
        .shadow(color: .black.opacity(0.04), radius: 16, y: 4)
        .padding(.horizontal, Spacing.l)
    }

    private func metric(value: Decimal, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value, format: .number.precision(.fractionLength(2)))
                .font(Typography.font(for: .amount))
                .foregroundStyle(color)
            Text(label)
                .font(Typography.font(for: .label))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Stats

    private func statGrid(_ vm: DashboardViewModel) -> some View {
        HStack(spacing: Spacing.s) {
            stat(icon: "person.2.fill", value: "\(vm.monthlyStats.totalPersonCount)", label: String(localized: "dashboard.month.people"))
            stat(icon: "clock.fill", value: "\(vm.monthlyStats.pendingDebtCount)", label: String(localized: "dashboard.month.pending"))
            stat(icon: "bolt.fill", value: "\(vm.monthlyStats.activePersonCount)", label: String(localized: "dashboard.month.active"))
        }
        .padding(.horizontal, Spacing.l)
    }

    private func stat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(ColorTokens.accent)
            Text(value)
                .font(Typography.font(for: .headline))
            Text(label)
                .font(Typography.font(for: .label))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.l)
        .background(ColorTokens.surface, in: .rect(cornerRadius: Radius.lg))
    }

    // MARK: Actions

    private func actionRow(_ vm: DashboardViewModel) -> some View {
        HStack(spacing: Spacing.m) {
            NavigationLink { PeopleListView() } label: {
                action(icon: "person.badge.plus", title: String(localized: "dashboard.action.people"))
            }
            NavigationLink {
                ChartsHostView(totalReceivable: vm.totalReceivable, totalPayable: vm.totalPayable, netBalance: vm.netBalance)
            } label: {
                action(icon: "chart.line.uptrend.xyaxis", title: String(localized: "dashboard.action.charts"))
            }
        }
        .padding(.horizontal, Spacing.l)
    }

    private func action(icon: String, title: String) -> some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(ColorTokens.accent)
            Text(title)
                .font(Typography.font(for: .headline))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity)
        .background(ColorTokens.surface, in: .rect(cornerRadius: Radius.lg))
    }

    // MARK: Currency

    private func currencyRow(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(String(localized: "dashboard.currency.title"))
                .font(Typography.font(for: .title2))
                .padding(.horizontal, Spacing.l)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s) {
                    ForEach(vm.currencyDistribution, id: \.kind) { item in
                        VStack(spacing: 4) {
                            Text(item.kind.format(item.total))
                                .font(Typography.font(for: .amount))
                            Text(item.kind.rawValue)
                                .font(Typography.font(for: .label))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, Spacing.l)
                        .padding(.vertical, Spacing.m)
                        .background(ColorTokens.surface, in: .rect(cornerRadius: Radius.md))
                    }
                }
                .padding(.horizontal, Spacing.l)
            }
        }
    }

    // MARK: Activity

    private func activityList(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(String(localized: "dashboard.recent.title"))
                .font(Typography.font(for: .title2))
                .padding(.horizontal, Spacing.l)

            VStack(spacing: 0) {
                ForEach(Array(vm.recentActivity.enumerated()), id: \.element.id) { i, item in
                    activityRow(item)
                    if i < vm.recentActivity.count - 1 { Divider().padding(.leading, 48) }
                }
            }
            .background(ColorTokens.surface, in: .rect(cornerRadius: Radius.lg))
            .padding(.horizontal, Spacing.l)
        }
    }

    private func activityRow(_ item: ActivityItem) -> some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: item.direction == .receivable ? "arrow.down.left" : "arrow.up.right")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(item.direction == .receivable ? ColorTokens.positive : ColorTokens.negative)
                .frame(width: 28, height: 28)
                .background((item.direction == .receivable ? ColorTokens.positive : ColorTokens.negative).opacity(0.12), in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.personName).font(Typography.font(for: .headline))
                Text(item.date, format: .relative(presentation: .named))
                    .font(Typography.font(for: .label)).foregroundStyle(.tertiary)
            }
            Spacer()
            Text(item.direction == .receivable ? "+\(item.kind.format(item.amount))" : "-\(item.kind.format(item.amount))")
                .font(Typography.font(for: .amount))
                .foregroundStyle(item.direction == .receivable ? ColorTokens.positive : ColorTokens.negative)
        }
        .padding(Spacing.m)
    }

    // MARK: Upcoming

    private func upcomingList(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(String(localized: "dashboard.upcoming.title"))
                .font(Typography.font(for: .title2))
                .padding(.horizontal, Spacing.l)

            VStack(spacing: 0) {
                ForEach(Array(vm.upcomingItems.enumerated()), id: \.element.id) { i, item in
                    HStack(spacing: Spacing.m) {
                        AvatarView(name: item.person.name, size: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.person.name).font(Typography.font(for: .headline))
                            if let due = item.dueDate {
                                Text(due, format: .dateTime.day().month(.abbreviated))
                                    .font(Typography.font(for: .label)).foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                        Text(item.amount.formatted())
                            .font(Typography.font(for: .amount))
                            .foregroundStyle(ColorTokens.positive)
                    }
                    .padding(Spacing.m)
                    if i < vm.upcomingItems.count - 1 { Divider().padding(.leading, 52) }
                }
            }
            .background(ColorTokens.surface, in: .rect(cornerRadius: Radius.lg))
            .padding(.horizontal, Spacing.l)
        }
    }

    // MARK: Helpers

    private func balanceColor(_ balance: Decimal) -> Color {
        balance.isEffectivelyZero ? ColorTokens.textPrimary : balance > 0 ? ColorTokens.positive : ColorTokens.negative
    }
}

#Preview {
    NavigationStack { DashboardView() }
}
