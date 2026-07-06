import SwiftUI
import SwiftData
import DesignSystem
import Domain
import Core
import Data
import FeatureDebtDetail

// MARK: - People List View

public struct PeopleListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PeopleListViewModel?
    @State private var showAddPerson = false
    @State private var searchText = ""

    public init() {}

    public var body: some View {
        Group {
            if let vm = viewModel {
                contentView(vm)
            } else {
                ProgressView()
                    .task {
                        let vm = PeopleListViewModel(modelContext: modelContext)
                        viewModel = vm
                        await vm.loadPersons()
                    }
            }
        }
        .sheet(isPresented: $showAddPerson) {
            AddPersonSheet { name, phone, notes in
                await viewModel?.addPerson(name: name, phoneNumber: phone, notes: notes)
                showAddPerson = false
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func contentView(_ vm: PeopleListViewModel) -> some View {
        VStack(spacing: 0) {
            // Segment picker
            Picker(
                String(localized: "people.segment.label"),
                selection: Binding(
                    get: { vm.selectedSegment },
                    set: { vm.selectedSegment = $0 }
                )
            ) {
                Text(String(localized: "people.segment.receivable"))
                    .tag(PeopleSegment.receivable)
                Text(String(localized: "people.segment.payable"))
                    .tag(PeopleSegment.payable)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)

            // List
            let filtered = vm.filteredPersons.filter { item in
                searchText.isEmpty || item.person.name.localizedCaseInsensitiveContains(searchText)
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
                    ForEach(Array(filtered.enumerated()), id: \.element.person.id) { index, item in
                        NavigationLink {
                            PersonDetailView(person: item.person, modelContext: modelContext)
                        } label: {
                            LedgerRowView(
                                name: item.person.name,
                                amount: item.balance,
                                subtitle: item.person.phoneNumber ?? item.person.notes,
                                isPositive: vm.selectedSegment == .receivable
                            )
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.8)
                            .delay(Double(index) * 0.05),
                            value: filtered.count
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color.vdBackground)
        .navigationTitle(String(localized: "people.navigationTitle"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddPerson = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable { await vm.loadPersons() }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: String(localized: "people.search.placeholder")
        )
    }
}

// MARK: - Add Person Sheet

private struct AddPersonSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var notes = ""
    @State private var showContactsPicker = false
    @State private var contacts: [ContactInfo] = []
    @State private var contactsLoaded = false

    let onSave: (String, String?, String?) async -> Void
    private let contactsService = ContactsService()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        String(localized: "people.add.namePlaceholder"),
                        text: $name
                    )
                    TextField(
                        String(localized: "people.add.phonePlaceholder"),
                        text: $phoneNumber
                    )
                    .keyboardType(.phonePad)
                    TextField(
                        String(localized: "people.add.notesPlaceholder"),
                        text: $notes
                    )
                }

                Section {
                    Button {
                        Task {
                            await loadContacts()
                            showContactsPicker = true
                        }
                    } label: {
                        Label(
                            String(localized: "people.add.fromContacts"),
                            systemImage: "person.crop.circle.badge.plus"
                        )
                    }
                }
            }
            .sheet(isPresented: $showContactsPicker) {
                contactsPickerSheet
            }
            .navigationTitle(String(localized: "people.add.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "people.add.cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "people.add.save")) {
                        Task {
                            await onSave(
                                name.trimmingCharacters(in: .whitespaces),
                                phoneNumber.isEmpty ? nil : phoneNumber.trimmingCharacters(in: .whitespaces),
                                notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
                            )
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func loadContacts() async {
        guard !contactsLoaded else { return }
        _ = await contactsService.requestPermission()
        contacts = (try? await contactsService.fetchAll()) ?? []
        contactsLoaded = true
    }

    private var contactsPickerSheet: some View {
        NavigationStack {
            List(contacts, id: \.name) { contact in
                Button {
                    name = contact.name
                    phoneNumber = contact.phoneNumber ?? ""
                    showContactsPicker = false
                } label: {
                    VStack(alignment: .leading) {
                        Text(contact.name)
                            .font(Typography.font(for: .body))
                            .foregroundColor(Color.vdInk900)
                        if let phone = contact.phoneNumber {
                            Text(phone)
                                .font(Typography.font(for: .caption))
                                .foregroundColor(Color.vdInk400)
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "people.add.fromContacts"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "people.add.cancel")) {
                        showContactsPicker = false
                    }
                }
            }
        }
    }
}

#Preview {
    PeopleListView()
        .modelContainer(for: [PersonModel.self, DebtRecordModel.self, PaymentModel.self])
}
