import SwiftUI
import SwiftData
import DesignSystem
import Domain
import Data
import FeatureDebtDetail
import Observability

public struct PeopleListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PeopleListViewModel?
    @State private var showAddPerson = false
    @State private var analytics: any AnalyticsTracking = AnalyticsService()

    public init() {}

    public var body: some View {
        Group {
            if let vm = viewModel {
                contentView(vm)
            } else {
                ProgressView()
                    .task {
                        let vm = PeopleListViewModel(modelContext: modelContext, analytics: analytics)
                        viewModel = vm
                        await vm.loadPersons()
                    }
            }
        }
        .navigationTitle(String(localized: "tab.people"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(String(localized: "people.add.button"), systemImage: "person.badge.plus") {
                    showAddPerson = true
                }
            }
        }
        .sheet(isPresented: $showAddPerson) {
            AddPersonSheet { name, phone, notes in
                await viewModel?.addPerson(name: name, phoneNumber: phone, notes: notes)
                showAddPerson = false
            }
        }
        .refreshable { await viewModel?.loadPersons() }
    }

    // MARK: - Content

    private func contentView(_ vm: PeopleListViewModel) -> some View {
        List {
            if vm.persons.isEmpty {
                Section {
                    EmptyStateView(
                        title: String(localized: "people.empty.title"),
                        subtitle: String(localized: "people.empty.subtitle")
                    )
                    .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    ForEach(vm.persons) { person in
                        NavigationLink {
                            PersonDetailView(person: person, modelContext: modelContext)
                        } label: {
                            personRow(person, balance: vm.personBalances[person.id] ?? .zero)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Person Row

    private func personRow(_ person: Person, balance: Decimal) -> some View {
        HStack(spacing: Spacing.m) {
            AvatarView(name: person.name, size: 44)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(person.name)
                    .font(Typography.font(for: .headline))
                    .foregroundStyle(ColorTokens.textPrimary)
                if let phone = person.phoneNumber {
                    Text(phone)
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textTertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text(balance.formatted())
                    .font(Typography.font(for: .amount))
                    .foregroundStyle(balance >= 0 ? ColorTokens.positive : ColorTokens.negative)
                Text(balance >= 0
                    ? String(localized: "people.balance.receivable")
                    : String(localized: "people.balance.payable")
                )
                .font(.system(size: 11))
                .foregroundStyle(ColorTokens.textTertiary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Add Person Sheet

private struct AddPersonSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var notes = ""

    let onSave: (String, String?, String?) async -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "people.add.namePlaceholder"), text: $name)
                    TextField(String(localized: "people.add.phonePlaceholder"), text: $phone)
                    TextField(String(localized: "people.add.notesPlaceholder"), text: $notes)
                }
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
                                phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespaces),
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
    NavigationStack {
        PeopleListView()
    }
}
