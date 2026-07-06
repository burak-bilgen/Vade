import SwiftUI
import SwiftData
import DesignSystem
import Domain
import Data

public struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardViewModel?

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                if let vm = viewModel {
                    // MARK: - Hero Balance
                    heroBalanceSection(vm)
                        .padding(.top, Spacing.s)

                    // MARK: - Metric Tiles
                    HStack(spacing: Spacing.m) {
                        MetricTile(
                            label: String(localized: "dashboard.metrics.receivable"),
                            value: vm.totalReceivable,
                            color: ColorTokens.positive
                        )
                        MetricTile(
                            label: String(localized: "dashboard.metrics.payable"),
                            value: vm.totalPayable,
                            color: ColorTokens.negative
                        )
                    }
                    .padding(.horizontal, Spacing.l)

                    // MARK: - Quick Actions
                    quickActionsRow(vm)
                        .padding(.horizontal, Spacing.l)

                    // MARK: - Upcoming
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        SectionHeader(String(localized: "dashboard.upcoming.title"))
                            .padding(.horizontal, Spacing.l)

                        if vm.upcomingItems.isEmpty {
                            EmptyStateView(
                                title: String(localized: "dashboard.upcoming.emptyTitle"),
                                subtitle: String(localized: "dashboard.upcoming.emptySubtitle")
                            )
                            .padding(.horizontal, Spacing.l)
                        } else {
                            ForEach(vm.upcomingItems, id: \.id) { item in
                                upcomingRow(item)
                                    .padding(.horizontal, Spacing.l)
                            }
                        }
                    }

                    // MARK: - Stats Link
                    NavigationLink {
                        ChartsHostView(
                            totalReceivable: vm.totalReceivable,
                            totalPayable: vm.totalPayable,
                            netBalance: vm.netBalance
                        )
                    } label: {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 16, weight: .medium))
                            Text(String(localized: "dashboard.viewStatistics"))
                                .font(Typography.font(for: .headline))
                            Spacer()
                            Text("\(vm.persons.count) \(String(localized: "dashboard.peopleCount"))")
                                .font(Typography.font(for: .caption))
                                .foregroundStyle(ColorTokens.textTertiary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(ColorTokens.textTertiary)
                        }
                        .padding(Spacing.l)
                        .background(ColorTokens.surface)
                        .clipShape(.rect(cornerRadius: Radius.md))
                        .padding(.horizontal, Spacing.l)
                    }
                    .foregroundStyle(ColorTokens.textPrimary)
                }
            }
            .padding(.bottom, Spacing.xxxl)
        }
        .navigationTitle(String(localized: "tab.dashboard"))
        .task {
            let vm = DashboardViewModel(modelContext: modelContext)
            viewModel = vm
            await vm.loadData()
        }
        .refreshable {
            await viewModel?.loadData()
        }
    }

    // MARK: - Hero Balance

    private func heroBalanceSection(_ vm: DashboardViewModel) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(String(localized: "dashboard.netBalance"))
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textTertiary)
                .textCase(.uppercase)

            Text(vm.netBalance.formatted())
                .font(Typography.font(for: .display))
                .foregroundStyle(balanceColor(vm.netBalance))
                .contentTransition(.numericText())

            HStack(spacing: Spacing.xs) {
                Image(systemName: vm.netBalance >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(vm.netBalance >= 0 ? ColorTokens.positive : ColorTokens.negative)
                Text(vm.netBalance >= 0
                    ? String(localized: "dashboard.netPositive")
                    : String(localized: "dashboard.netNegative")
                )
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(ColorTokens.surface)
                .shadow(color: Elevation.cardShadow, radius: Elevation.cardShadowBlur, y: Elevation.cardShadowY)
        )
        .padding(.horizontal, Spacing.l)
    }

    // MARK: - Quick Actions

    private func quickActionsRow(_ vm: DashboardViewModel) -> some View {
        HStack(spacing: Spacing.s) {
            NavigationLink {
                PeopleListView()
            } label: {
                VStack(spacing: Spacing.s) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(ColorTokens.accent)
                        .frame(width: 44, height: 44)
                        .background(ColorTokens.accent.opacity(0.1))
                        .clipShape(.rect(cornerRadius: Radius.md))
                    Text(String(localized: "dashboard.action.people"))
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s)
            }
            .foregroundStyle(ColorTokens.textPrimary)

            NavigationLink {
                ChartsHostView(
                    totalReceivable: vm.totalReceivable,
                    totalPayable: vm.totalPayable,
                    netBalance: vm.netBalance
                )
            } label: {
                VStack(spacing: Spacing.s) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(ColorTokens.accent)
                        .frame(width: 44, height: 44)
                        .background(ColorTokens.accent.opacity(0.1))
                        .clipShape(.rect(cornerRadius: Radius.md))
                    Text(String(localized: "dashboard.action.charts"))
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s)
            }
            .foregroundStyle(ColorTokens.textPrimary)

            NavigationLink {
                PeopleListView()
            } label: {
                VStack(spacing: Spacing.s) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(ColorTokens.accent)
                        .frame(width: 44, height: 44)
                        .background(ColorTokens.accent.opacity(0.1))
                        .clipShape(.rect(cornerRadius: Radius.md))
                    Text(String(localized: "dashboard.action.newDebt"))
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s)
            }
            .foregroundStyle(ColorTokens.textPrimary)
        }
    }

    // MARK: - Upcoming Row

    private func upcomingRow(_ item: (id: UUID, person: Person, amount: Decimal, dueDate: Date?)) -> some View {
        HStack(spacing: Spacing.m) {
            AvatarView(name: item.person.name, size: 40)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(item.person.name)
                    .font(Typography.font(for: .headline))
                    .foregroundStyle(ColorTokens.textPrimary)
                if let dueDate = item.dueDate {
                    Text(dueDate, format: .dateTime.day().month(.abbreviated))
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textTertiary)
                }
            }

            Spacer()

            Text(item.amount.formatted())
                .font(Typography.font(for: .amount))
                .foregroundStyle(ColorTokens.positive)
        }
        .padding(Spacing.l)
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
    NavigationStack {
        DashboardView()
    }
}
