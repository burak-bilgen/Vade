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
        Group {
            if let vm = viewModel {
                contentView(vm)
            } else {
                ProgressView()
                    .task {
                        let vm = DashboardViewModel(modelContext: modelContext)
                        viewModel = vm
                        await vm.loadData()
                    }
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func contentView(_ vm: DashboardViewModel) -> some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                summarySection(vm)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                upcomingSection(vm)
                quickActionsSection
            }
            .padding(Spacing.l)
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: vm.netBalance)
        }
        .background(Color.vdBackground)
        .refreshable { await vm.loadData() }
    }

    // MARK: - Summary

    private func summarySection(_ vm: DashboardViewModel) -> some View {
        SummaryCard(
            netAmount: vm.netBalance,
            totalReceivable: vm.totalReceivable,
            totalPayable: vm.totalPayable
        )
    }

    // MARK: - Upcoming

    private func upcomingSection(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(String(localized: "dashboard.upcoming.title"))
                .font(Typography.font(for: .title2))
                .foregroundColor(Color.vdInk900)

            if vm.upcomingItems.isEmpty {
                EmptyStateView(
                    title: String(localized: "dashboard.upcoming.emptyTitle"),
                    subtitle: String(localized: "dashboard.upcoming.emptySubtitle")
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(vm.upcomingItems.prefix(5), id: \.person.id) { item in
                        LedgerRowView(
                            name: item.person.name,
                            amount: item.amount,
                            subtitle: item.dueDate?.formatted(date: .abbreviated, time: .omitted),
                            isPositive: item.amount > 0
                        )
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(Color.vdSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.vdHairline, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        HStack(spacing: Spacing.m) {
            NavigationLink {
                PeopleListView()
            } label: {
                VStack(spacing: Spacing.s) {
                    Image(systemName: "person.2.fill")
                        .font(.title2)
                    Text(String(localized: "dashboard.action.people"))
                        .font(Typography.font(for: .caption))
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.l)
                .background(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(Color.vdSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.vdHairline, lineWidth: 1)
                )
            }
            .foregroundColor(Color.vdInk900)
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [PersonModel.self, DebtRecordModel.self, PaymentModel.self])
}
