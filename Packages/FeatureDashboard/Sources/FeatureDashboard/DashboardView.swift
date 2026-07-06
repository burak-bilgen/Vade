import SwiftUI
import SwiftData
import DesignSystem
import Domain
import Data

// MARK: - Dashboard View (Wise/Revolut-style)

public struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardViewModel?

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                if let vm = viewModel {
                    heroBalance(vm)
                    quickActions(vm)
                    if !vm.recentActivity.isEmpty {
                        recentActivitySection(vm)
                    }
                    if !vm.upcomingItems.isEmpty {
                        upcomingSection(vm)
                    }
                    monthlyOverview(vm)
                }
            }
            .padding(.bottom, Spacing.xxxl)
        }
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            let vm = DashboardViewModel(modelContext: modelContext)
            viewModel = vm
            await vm.loadData()
        }
        .refreshable { await viewModel?.loadData() }
    }

    // MARK: - Hero Balance

    private func heroBalance(_ vm: DashboardViewModel) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(vm.netBalance, format: .number.precision(.fractionLength(2)))
                .font(Typography.font(for: .display))
                .foregroundStyle(balanceColor(vm.netBalance))
                .contentTransition(.numericText())
                .padding(.top, Spacing.l)

            HStack(spacing: Spacing.s) {
                Text(vm.netBalance >= 0
                    ? String(localized: "dashboard.youAreOwed")
                    : String(localized: "dashboard.youOwe")
                )
                .font(Typography.font(for: .body))
                .foregroundStyle(ColorTokens.textSecondary)
                Image(systemName: vm.netBalance >= 0 ? "arrow.up.right" : "arrow.down.left")
                    .font(.system(size: 14))
                    .foregroundStyle(vm.netBalance >= 0 ? ColorTokens.positive : ColorTokens.negative)
            }

            HStack(spacing: Spacing.xl) {
                metricPill(
                    label: String(localized: "dashboard.receivable"),
                    amount: vm.totalReceivable,
                    color: ColorTokens.positive
                )
                metricPill(
                    label: String(localized: "dashboard.payable"),
                    amount: vm.totalPayable,
                    color: ColorTokens.negative
                )
            }
            .padding(.top, Spacing.m)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .padding(.horizontal, Spacing.l)
        .background(ColorTokens.surface)
        .clipShape(.rect(cornerRadius: Radius.xl))
        .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
        .padding(.horizontal, Spacing.l)
        .padding(.top, Spacing.s)
    }

    private func metricPill(label: String, amount: Decimal, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(amount, format: .number.precision(.fractionLength(2)))
                .font(Typography.font(for: .amount))
                .foregroundStyle(color)
            Text(label)
                .font(Typography.font(for: .label))
                .foregroundStyle(ColorTokens.textTertiary)
        }
    }

    // MARK: - Quick Actions

    private func quickActions(_ vm: DashboardViewModel) -> some View {
        HStack(spacing: Spacing.s) {
            NavigationLink {
                PeopleListView()
            } label: {
                actionCard(icon: "person.2.fill", title: String(localized: "dashboard.action.people"), subtitle: "\(vm.persons.count)")
            }
            .foregroundStyle(.primary)

            NavigationLink {
                ChartsHostView(
                    totalReceivable: vm.totalReceivable,
                    totalPayable: vm.totalPayable,
                    netBalance: vm.netBalance
                )
            } label: {
                actionCard(icon: "chart.line.uptrend.xyaxis", title: String(localized: "dashboard.action.charts"), subtitle: String(localized: "dashboard.action.view"))
            }
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, Spacing.l)
    }

    private func actionCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(ColorTokens.accent)
                .frame(width: 36, height: 36)
                .background(ColorTokens.accent.opacity(0.1))
                .clipShape(.rect(cornerRadius: Radius.sm))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.font(for: .headline))
                Text(subtitle)
                    .font(Typography.font(for: .label))
                    .foregroundStyle(ColorTokens.textTertiary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity)
        .background(ColorTokens.surface)
        .clipShape(.rect(cornerRadius: Radius.md))
    }

    // MARK: - Recent Activity

    private func recentActivitySection(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(String(localized: "dashboard.recent.title"))
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)
                .padding(.horizontal, Spacing.l)

            VStack(spacing: 0) {
                ForEach(Array(vm.recentActivity.enumerated()), id: \.element.id) { index, item in
                    activityRow(item)
                    if index < vm.recentActivity.count - 1 {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(ColorTokens.surface)
            .clipShape(.rect(cornerRadius: Radius.md))
            .padding(.horizontal, Spacing.l)
        }
    }

    private func activityRow(_ item: ActivityItem) -> some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: item.direction == .receivable ? "arrow.down.left" : "arrow.up.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(item.direction == .receivable ? ColorTokens.positive : ColorTokens.negative)
                .frame(width: 32, height: 32)
                .background(
                    (item.direction == .receivable ? ColorTokens.positive : ColorTokens.negative)
                        .opacity(0.12)
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

            Text(item.direction == .receivable ? "+\(item.kind.format(item.amount))" : "-\(item.kind.format(item.amount))")
                .font(Typography.font(for: .amount))
                .foregroundStyle(item.direction == .receivable ? ColorTokens.positive : ColorTokens.negative)
        }
        .padding(Spacing.m)
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
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(ColorTokens.surface)
            .clipShape(.rect(cornerRadius: Radius.md))
            .padding(.horizontal, Spacing.l)
        }
    }

    // MARK: - Monthly Overview

    private func monthlyOverview(_ vm: DashboardViewModel) -> some View {
        HStack(spacing: Spacing.s) {
            statCell(String(localized: "dashboard.month.people"), "\(vm.monthlyStats.totalPersonCount)")
            statCell(String(localized: "dashboard.month.active"), "\(vm.monthlyStats.activePersonCount)")
            statCell(String(localized: "dashboard.month.pending"), "\(vm.monthlyStats.pendingDebtCount)")
        }
        .padding(.horizontal, Spacing.l)
    }

    private func statCell(_ title: String, _ value: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(Typography.font(for: .title2))
                .foregroundStyle(ColorTokens.textPrimary)
            Text(title)
                .font(Typography.font(for: .label))
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.m)
        .background(ColorTokens.surface)
        .clipShape(.rect(cornerRadius: Radius.md))
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
