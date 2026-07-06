import SwiftUI
import SwiftData
import DesignSystem
import Domain

// MARK: - People List View

public struct PeopleListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PeopleListViewModel?
    @State private var showAddPerson = false

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
                String(localized: "people.segment.label", bundle: .module),
                selection: Binding(
                    get: { vm.selectedSegment },
                    set: { vm.selectedSegment = $0 }
                )
            ) {
                Text(String(localized: "people.segment.receivable", bundle: .module))
                    .tag(PeopleSegment.receivable)
                Text(String(localized: "people.segment.payable", bundle: .module))
                    .tag(PeopleSegment.payable)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)

            // List
            if vm.filteredPersons.isEmpty {
                Spacer()
                EmptyStateView(
                    title: String(localized: "people.empty.title", bundle: .module),
                    subtitle: String(localized: "people.empty.subtitle", bundle: .module)
                )
                Spacer()
            } else {
                List {
                    ForEach(vm.filteredPersons, id: \.person.id) { item in
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
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color("background", bundle: .module))
        .navigationTitle(String(localized: "people.navigationTitle", bundle: .module))
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
    }
}

// MARK: - Add Person Sheet

private struct AddPersonSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var notes = ""

    let onSave: (String, String?, String?) async -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        String(localized: "people.add.namePlaceholder", bundle: .module),
                        text: $name
                    )
                    TextField(
                        String(localized: "people.add.phonePlaceholder", bundle: .module),
                        text: $phoneNumber
                    )
                    .keyboardType(.phonePad)
                    TextField(
                        String(localized: "people.add.notesPlaceholder", bundle: .module),
                        text: $notes
                    )
                }
            }
            .navigationTitle(String(localized: "people.add.title", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "people.add.cancel", bundle: .module)) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "people.add.save", bundle: .module)) {
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
}

#Preview {
    PeopleListView()
        .modelContainer(for: [PersonModel.self, DebtRecordModel.self, PaymentModel.self])
}
