import SwiftUI
import SwiftData
import DesignSystem
import Domain
import Core
import Data
import FeatureDebtDetail

public struct PeopleListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var persons: [Person] = []
    @State private var balances: [UUID: Decimal] = [:]
    @State private var selectedSegment: PeopleSegment = .receivable
    @State private var searchText = ""
    @State private var showAddPerson = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedSegment) {
                Text(String(localized: "people.segment.receivable")).tag(PeopleSegment.receivable)
                Text(String(localized: "people.segment.payable")).tag(PeopleSegment.payable)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)

            let filtered = persons.compactMap { person -> (Person, Decimal)? in
                guard let balance = balances[person.id], searchText.isEmpty || person.name.localizedCaseInsensitiveContains(searchText) else { return nil }
                switch selectedSegment {
                case .receivable: return balance > 0 ? (person, balance) : nil
                case .payable: return balance < 0 ? (person, balance.magnitude) : nil
                }
            }

            if filtered.isEmpty {
                Spacer()
                EmptyStateView(
                    title: String(localized: "people.empty.title"),
                    subtitle: String(localized: "people.empty.subtitle")
                )
                Spacer()
            } else {
                List {
                    ForEach(filtered, id: \.0.id) { person, balance in
                        NavigationLink {
                            PersonDetailView(person: person, modelContext: modelContext)
                        } label: {
                            LedgerRowView(
                                name: person.name,
                                amount: balance,
                                subtitle: person.phoneNumber ?? person.notes,
                                isPositive: selectedSegment == .receivable
                            )
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color.vdBackground)
        .navigationTitle(String(localized: "people.navigationTitle"))
        .searchable(text: $searchText, prompt: String(localized: "people.search.placeholder"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddPerson = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAddPerson) {
            AddPersonWrapper(isPresented: $showAddPerson, modelContext: modelContext) {
                await load()
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        let repo = PersonRepository(modelContext: modelContext)
        let balanceRepo = BalanceRepository(modelContext: modelContext)
        guard let list = try? await repo.execute(includeArchived: false) else { return }
        persons = list
        var b: [UUID: Decimal] = [:]
        for p in list {
            b[p.id] = (try? await balanceRepo.execute(for: p.id)) ?? .zero
        }
        balances = b
    }

}

// MARK: - AddPersonWrapper

private struct AddPersonWrapper: View {
    @Binding var isPresented: Bool
    let modelContext: ModelContext
    let onDone: () async -> Void
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField(String(localized: "people.add.namePlaceholder"), text: $name)
            }
            .navigationTitle(String(localized: "people.add.title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "people.add.cancel")) { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "people.add.save")) {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        Task {
                            let repo = PersonRepository(modelContext: modelContext)
                            _ = try? await repo.execute(name: trimmed, phoneNumber: nil, notes: nil)
                            isPresented = false
                            await onDone()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    PeopleListView()
}
