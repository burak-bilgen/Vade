import SwiftUI
import SwiftData
import DesignSystem
import Domain
import Data

public struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var netBalance: Decimal = .zero
    @State private var totalReceivable: Decimal = .zero
    @State private var totalPayable: Decimal = .zero
    @State private var personCount: Int = 0

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                SummaryCard(
                    netAmount: netBalance,
                    totalReceivable: totalReceivable,
                    totalPayable: totalPayable
                )

                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text(String(localized: "dashboard.upcoming.title"))
                        .font(Typography.font(for: .title2))
                        .foregroundColor(Color.vdInk900)

                    EmptyStateView(
                        title: String(localized: "dashboard.upcoming.emptyTitle"),
                        subtitle: String(localized: "dashboard.upcoming.emptySubtitle")
                    )
                }

                NavigationLink {
                    PeopleListView()
                } label: {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text(String(localized: "dashboard.action.people"))
                            .font(Typography.font(for: .caption))
                        Spacer()
                        Text("\(personCount)")
                            .font(Typography.font(for: .amount))
                            .foregroundColor(Color.vdBrass500)
                    }
                    .padding(Spacing.l)
                    .background(RoundedRectangle(cornerRadius: Radius.md).fill(Color.vdSurface))
                    .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(Color.vdHairline, lineWidth: 1))
                }
                .foregroundColor(Color.vdInk900)
            }
            .padding(Spacing.l)
        }
        .background(Color.vdBackground)
        .navigationTitle(String(localized: "tab.dashboard"))
        .task { await refresh() }
        .refreshable { await refresh() }
    }

    private func refresh() async {
        let personRepo = PersonRepository(modelContext: modelContext)
        let balanceRepo = BalanceRepository(modelContext: modelContext)
        guard let persons = try? await personRepo.execute(includeArchived: false) else { return }
        personCount = persons.count
        var receivable: Decimal = .zero
        var payable: Decimal = .zero
        for person in persons {
            if let balance = try? await balanceRepo.execute(for: person.id) {
                if balance > 0 { receivable += balance }
                else if balance < 0 { payable += balance.magnitude }
            }
        }
        totalReceivable = receivable
        totalPayable = payable
        netBalance = receivable - payable
    }
}

#Preview {
    DashboardView()
}
