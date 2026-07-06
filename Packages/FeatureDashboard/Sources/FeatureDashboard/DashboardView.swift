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
                    SummaryCard(
                        netAmount: vm.netBalance,
                        totalReceivable: vm.totalReceivable,
                        totalPayable: vm.totalPayable
                    )
                    .accessibilityLabel(String(localized: "Net durum: \(vm.netBalance.formatted())"))

                    // Yaklasan Odemeler section
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        Text(String(localized: "dashboard.upcoming.title"))
                            .font(Typography.font(for: .title2))
                            .foregroundStyle(ColorTokens.textPrimary)

                        if vm.upcomingItems.isEmpty {
                            EmptyStateView(
                                title: String(localized: "dashboard.upcoming.emptyTitle"),
                                subtitle: String(localized: "dashboard.upcoming.emptySubtitle")
                            )
                        } else {
                            ForEach(vm.upcomingItems, id: \.id) { item in
                                upcomingRow(item)
                            }
                        }
                    }

                    // View Statistics link
                    NavigationLink {
                        ChartsHostView(
                            totalReceivable: vm.totalReceivable,
                            totalPayable: vm.totalPayable,
                            netBalance: vm.netBalance
                        )
                    } label: {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                            Text(String(localized: "dashboard.viewStatistics"))
                                .font(Typography.font(for: .caption))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(ColorTokens.textTertiary)
                        }
                        .padding(Spacing.l)
                        .background(RoundedRectangle(cornerRadius: Radius.md).fill(ColorTokens.surface))
                        .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(ColorTokens.border, lineWidth: 1))
                    }
                    .foregroundStyle(ColorTokens.textPrimary)
                    .accessibilityLabel(String(localized: "dashboard.viewStatistics"))

                    NavigationLink {
                        PeopleListView()
                    } label: {
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text(String(localized: "dashboard.action.people"))
                                .font(Typography.font(for: .caption))
                            Spacer()
                            Text("\(vm.persons.count)")
                                .font(Typography.font(for: .amount))
                                .foregroundStyle(ColorTokens.accent)
                                .minimumScaleFactor(0.85)
                        }
                        .padding(Spacing.l)
                        .background(RoundedRectangle(cornerRadius: Radius.md).fill(ColorTokens.surface))
                        .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(ColorTokens.border, lineWidth: 1))
                    }
                    .foregroundStyle(ColorTokens.textPrimary)
                    .accessibilityLabel(String(localized: "dashboard.action.people"))
                }
            }
            .padding(Spacing.l)
        }
        .background(ColorTokens.background)
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

    private func upcomingRow(_ item: (id: UUID, person: Person, amount: Decimal, dueDate: Date?)) -> some View {
        HStack(spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(item.person.name)
                    .font(Typography.font(for: .headline))
                    .foregroundStyle(ColorTokens.textPrimary)
                    .minimumScaleFactor(0.85)
                if let dueDate = item.dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textTertiary)
                }
            }
            Spacer()
            Text(item.amount.formatted())
                .font(Typography.font(for: .amount))
                .foregroundStyle(ColorTokens.positive)
                .minimumScaleFactor(0.85)
        }
        .padding(Spacing.m)
        .background(RoundedRectangle(cornerRadius: Radius.sm).fill(ColorTokens.surface))
    }
}

#Preview {
    DashboardView()
}
