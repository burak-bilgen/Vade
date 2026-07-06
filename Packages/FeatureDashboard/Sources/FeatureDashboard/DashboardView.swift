import SwiftUI
import SwiftData
import DesignSystem
import Domain
import Data

// MARK: - Dashboard View

public struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardViewModel?

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: Spacing.l) {
                if let vm = viewModel {
                    exchangeRateTicker(vm)
                    heroCard(vm)
                    quickStatsRow(vm)
                    quickActionsRow(vm)
                    if !vm.currencyDistribution.isEmpty {
                        currencyBreakdown(vm)
                    }
                    if !vm.recentActivity.isEmpty {
                        activityFeed(vm)
                    }
                    if !vm.upcomingItems.isEmpty {
                        upcomingSection(vm)
                    }
                }
            }
            .padding(.bottom, Spacing.xxxl)
        }
        .task {
            let vm = DashboardViewModel(modelContext: modelContext)
            viewModel = vm
            await vm.loadData()
        }
        .refreshable { await viewModel?.loadData() }
    }

    // MARK: - Exchange Rate Ticker

    private func exchangeRateTicker(_ vm: DashboardViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                if let rates = vm.exchangeRates {
                    ratePill(flag: "🇺🇸", code: "USD", rate: rates.usdRate)
                    ratePill(flag: "🇪🇺", code: "EUR", rate: rates.eurRate)
                    ratePill(flag: "🪙", code: "XAU", rate: rates.goldRate, isGold: true)
                } else {
                    ProgressView()
                        .padding(.horizontal, Spacing.l)
                }
            }
            .padding(.horizontal, Spacing.l)
        }
        .padding(.top, Spacing.s)
    }

    private func ratePill(flag: String, code: String, rate: Decimal?, isGold: Bool = false) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(flag)
            Text(code)
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textSecondary)
            if let rate {
                Text(isGold ? rate.formatted() : rate.formatted())
                    .font(Typography.font(for: .amount))
                    .foregroundStyle(ColorTokens.textPrimary)
            }
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .background(ColorTokens.surface)
        .clipShape(.rect(cornerRadius: Radius.pill))
    }

    // MARK: - Hero Card

    private func heroCard(_ vm: DashboardViewModel) -> some View {
        VStack(spacing: Spacing.m) {
            Text(vm.netBalance.formatted())
                .font(Typography.font(for: .display))
                .foregroundStyle(balanceColor(vm.netBalance))
                .contentTransition(.numericText())

            Text(vm.netBalance >= 0
                ? String(localized: "dashboard.youAreOwed")
                : String(localized: "dashboard.youOwe")
            )
            .font(Typography.font(for: .body))
            .foregroundStyle(ColorTokens.textSecondary)

            Divider().padding(.horizontal, Spacing.xl)

            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text(vm.totalReceivable.formatted())
                        .font(Typography.font(for: .amount))
                        .foregroundStyle(ColorTokens.positive)
                    Text(String(localized: "dashboard.receivable"))
                        .font(Typography.font(for: .label))
                        .foregroundStyle(ColorTokens.textTertiary)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 32)

                VStack(spacing: 2) {
                    Text(vm.totalPayable.formatted())
                        .font(Typography.font(for: .amount))
                        .foregroundStyle(ColorTokens.negative)
                    Text(String(localized: "dashboard.payable"))
                        .font(Typography.font(for: .label))
                        .foregroundStyle(ColorTokens.textTertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(Spacing.xl)
        .background(ColorTokens.surface)
        .clipShape(.rect(cornerRadius: Radius.xl))
        .shadow(color: .black.opacity(0.04), radius: 16, y: 4)
        .padding(.horizontal, Spacing.l)
    }

    // MARK: - Quick Stats

    private func quickStatsRow(_ vm: DashboardViewModel) -> some View {
        HStack(spacing: Spacing.s) {
            statCard(
                icon: "person.2",
                value: "\(vm.monthlyStats.totalPersonCount)",
                label: String(localized: "dashboard.month.people")
            )
            statCard(
                icon: "clock",
                value: "\(vm.monthlyStats.pendingDebtCount)",
                label: String(localized: "dashboard.month.pending")
            )
            statCard(
                icon: "chart.bar",
                value: "\(vm.monthlyStats.activePersonCount)",
                label: String(localized: "dashboard.month.active")
            )
        }
        .padding(.horizontal, Spacing.l)
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(ColorTokens.accent)
            Text(value)
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)
            Text(label)
                .font(Typography.font(for: .label))
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.l)
        .background(ColorTokens.surface)
        .clipShape(.rect(cornerRadius: Radius.lg))
    }

    // MARK: - Quick Actions

    private func quickActionsRow(_ vm: DashboardViewModel) -> some View {
        HStack(spacing: Spacing.m) {
            NavigationLink {
                PeopleListView()
            } label: {
                actionLabel(icon: "person.badge.plus", title: String(localized: "dashboard.action.people"))
            }
            NavigationLink {
                ChartsHostView(
                    totalReceivable: vm.totalReceivable,
                    totalPayable: vm.totalPayable,
                    netBalance: vm.netBalance
                )
            } label: {
                actionLabel(icon: "chart.line.uptrend.xyaxis", title: String(localized: "dashboard.action.charts"))
            }
        }
        .padding(.horizontal, Spacing.l)
    }

    private func actionLabel(icon: String, title: String) -> some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(ColorTokens.accent)
            Text(title)
                .font(Typography.font(for: .headline))
                .foregroundStyle(ColorTokens.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity)
        .background(ColorTokens.surface)
        .clipShape(.rect(cornerRadius: Radius.lg))
    }

    // MARK: - Currency Breakdown

    private func currencyBreakdown(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(String(localized: "dashboard.currency.title"))
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)
                .padding(.horizontal, Spacing.l)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s) {
                    ForEach(vm.currencyDistribution, id: \.kind) { item in
                        VStack(spacing: Spacing.xs) {
                            Text(item.kind.format(item.total))
                                .font(Typography.font(for: .amount))
                                .foregroundStyle(ColorTokens.textPrimary)
                            Text(item.kind.rawValue)
                                .font(Typography.font(for: .label))
                                .foregroundStyle(ColorTokens.textTertiary)
                        }
                        .padding(.horizontal, Spacing.l)
                        .padding(.vertical, Spacing.m)
                        .background(ColorTokens.surface)
                        .clipShape(.rect(cornerRadius: Radius.md))
                    }
                }
                .padding(.horizontal, Spacing.l)
            }
        }
    }

    // MARK: - Activity Feed

    private func activityFeed(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(String(localized: "dashboard.recent.title"))
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)
                .padding(.horizontal, Spacing.l)

            VStack(spacing: 0) {
                ForEach(Array(vm.recentActivity.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: Spacing.m) {
                        Image(systemName: item.direction == .receivable
                            ? "arrow.down.left" : "arrow.up.right"
                        )
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(item.direction == .receivable
                            ? ColorTokens.positive : ColorTokens.negative
                        )
                        .frame(width: 28, height: 28)
                        .background(
                            (item.direction == .receivable
                                ? ColorTokens.positive : ColorTokens.negative
                            ).opacity(0.12)
                        )
                        .clipShape(.circle)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.personName)
                                .font(Typography.font(for: .headline))
                            Text(item.date, format: .relative(presentation: .named))
                                .font(Typography.font(for: .label))
                                .foregroundStyle(ColorTokens.textTertiary)
                        }
                        Spacer()
                        Text(item.direction == .receivable
                            ? "+\(item.kind.format(item.amount))"
                            : "-\(item.kind.format(item.amount))"
                        )
                        .font(Typography.font(for: .amount))
                        .foregroundStyle(item.direction == .receivable
                            ? ColorTokens.positive : ColorTokens.negative
                        )
                    }
                    .padding(Spacing.m)

                    if index < vm.recentActivity.count - 1 {
                        Divider().padding(.leading, 48)
                    }
                }
            }
            .background(ColorTokens.surface)
            .clipShape(.rect(cornerRadius: Radius.lg))
            .padding(.horizontal, Spacing.l)
        }
    }

    // MARK: - Upcoming

    private func upcomingSection(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(String(localized: "dashboard.upcoming.title"))
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)
                .padding(.horizontal, Spacing.l)

            VStack(spacing: 0) {
                ForEach(Array(vm.upcomingItems.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: Spacing.m) {
                        AvatarView(name: item.person.name, size: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.person.name)
                                .font(Typography.font(for: .headline))
                            if let due = item.dueDate {
                                Text(due, format: .dateTime.day().month(.abbreviated))
                                    .font(Typography.font(for: .label))
                                    .foregroundStyle(ColorTokens.textTertiary)
                            }
                        }
                        Spacer()
                        Text(item.amount.formatted())
                            .font(Typography.font(for: .amount))
                            .foregroundStyle(ColorTokens.positive)
                    }
                    .padding(Spacing.m)
                    if index < vm.upcomingItems.count - 1 {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(ColorTokens.surface)
            .clipShape(.rect(cornerRadius: Radius.lg))
            .padding(.horizontal, Spacing.l)
        }
    }

    // MARK: - Helpers

    private func balanceColor(_ balance: Decimal) -> Color {
        if balance.isEffectivelyZero { return ColorTokens.textPrimary }
        return balance > 0 ? ColorTokens.positive : ColorTokens.negative
    }
}

#Preview {
    NavigationStack { DashboardView() }
}
