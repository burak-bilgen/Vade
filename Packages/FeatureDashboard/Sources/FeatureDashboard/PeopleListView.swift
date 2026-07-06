import SwiftUI
import SwiftData
import DesignSystem
import Domain
import FeatureDebtDetail
import Core
import Observability

public struct PeopleListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PeopleListViewModel?
    @State private var searchText = ""
    @State private var showAddPerson = false
    @State private var analytics: any AnalyticsTracking = AnalyticsService()

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            if let vm = viewModel {
                Picker("", selection: Binding(get: { vm.selectedSegment }, set: { vm.selectedSegment = $0 })) {
                    Text(String(localized: "people.segment.receivable")).tag(PeopleSegment.receivable)
                    Text(String(localized: "people.segment.payable")).tag(PeopleSegment.payable)
                }
                .pickerStyle(.segmented)
                .tint(ColorTokens.accent)
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.m)

                let filtered = vm.filteredPersons.filter { person, _ in
                    searchText.isEmpty || person.name.localizedCaseInsensitiveContains(searchText)
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
                        ForEach(filtered, id: \.person.id) { person, balance in
                            NavigationLink {
                                PersonDetailView(person: person, modelContext: modelContext)
                            } label: {
                                LedgerRowView(
                                    name: person.name,
                                    amount: balance,
                                    subtitle: person.phoneNumber ?? person.notes,
                                    isPositive: vm.selectedSegment == .receivable
                                )
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(String(localized: "people.navigationTitle"))
        .searchable(text: $searchText, prompt: String(localized: "people.search.placeholder"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker(String(localized: "people.filter.all"), selection: Binding(
                        get: { viewModel?.selectedStatusFilter ?? .all },
                        set: { viewModel?.selectedStatusFilter = $0 }
                    )) {
                        Text(String(localized: "people.filter.all")).tag(DebtStatusFilter.all)
                        Text(String(localized: "people.filter.pending")).tag(DebtStatusFilter.pending)
                        Text(String(localized: "people.filter.paid")).tag(DebtStatusFilter.paid)
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button { showAddPerson = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAddPerson) {
            AddPersonWrapper(isPresented: $showAddPerson, modelContext: modelContext, analytics: analytics) {
                await viewModel?.loadPersons()
            }
        }
        .task {
            let vm = PeopleListViewModel(modelContext: modelContext, analytics: analytics)
            viewModel = vm
            await vm.loadPersons()
        }
        .refreshable { await viewModel?.loadPersons() }
    }
}

// MARK: - AddPersonWrapper

private struct AddPersonWrapper: View {
    @Binding var isPresented: Bool
    let modelContext: ModelContext
    let analytics: any AnalyticsTracking
    let onDone: () async -> Void
    @State private var name = ""
    @State private var contacts: [ContactInfo] = []
    @State private var showContactPicker = false

    var body: some View {
        NavigationStack {
            Form {
                TextField(String(localized: "people.add.namePlaceholder"), text: $name)

                Button(String(localized: "people.add.fromContacts")) {
                    Task {
                        contacts = (try? await ContactsService().fetchAll()) ?? []
                        showContactPicker = true
                    }
                }
            }
            .sheet(isPresented: $showContactPicker) {
                NavigationStack {
                    List(contacts, id: \.name) { contact in
                        Button {
                            name = contact.name
                            showContactPicker = false
                        } label: {
                            VStack(alignment: .leading) {
                                Text(contact.name)
                                if let phone = contact.phoneNumber {
                                    Text(phone)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .navigationTitle(String(localized: "people.add.contactPickerTitle"))
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(String(localized: "people.add.cancel")) { showContactPicker = false }
                        }
                    }
                }
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
                            let vm = PeopleListViewModel(modelContext: modelContext, analytics: analytics)
                            await vm.addPerson(name: trimmed, phoneNumber: nil, notes: nil)
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
