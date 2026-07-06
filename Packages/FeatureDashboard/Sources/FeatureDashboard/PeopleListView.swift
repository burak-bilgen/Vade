import SwiftUI
import SwiftData
import DesignSystem
import Domain
import Data
import FeatureDebtDetail
import Observability

// MARK: - People List

public struct PeopleListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PeopleListViewModel?
    @State private var showAdd = false
    @State private var analytics: any AnalyticsTracking = AnalyticsService()

    public init() {}

    public var body: some View {
        Group {
            if let vm = viewModel {
                content(vm)
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
                    showAdd = true
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddSheet { name, phone, notes in
                await viewModel?.addPerson(name: name, phoneNumber: phone, notes: notes)
                showAdd = false
            }
        }
        .refreshable { await viewModel?.loadPersons() }
        .background(ColorTokens.background)
    }

    // MARK: Content

    private func content(_ vm: PeopleListViewModel) -> some View {
        List {
            if vm.persons.isEmpty {
                VStack(spacing: Spacing.l) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text(String(localized: "people.empty.title"))
                        .font(Typography.font(for: .headline))
                        .foregroundStyle(.secondary)
                    Text(String(localized: "people.empty.subtitle"))
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xxxl)
                .listRowBackground(Color.clear)
            } else {
                ForEach(vm.persons) { person in
                    NavigationLink {
                        PersonDetailView(person: person, modelContext: modelContext)
                    } label: {
                        row(person, balance: vm.personBalances[person.id] ?? .zero)
                    }
                    .listRowBackground(ColorTokens.surface)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: Row

    private func row(_ person: Person, balance: Decimal) -> some View {
        HStack(spacing: Spacing.m) {
            AvatarView(name: person.name, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(Typography.font(for: .headline))
                if let phone = person.phoneNumber {
                    Text(phone)
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(balance, format: .number.precision(.fractionLength(2)))
                    .font(Typography.font(for: .amount))
                    .foregroundStyle(balance >= 0 ? ColorTokens.positive : ColorTokens.negative)
                Text(balance >= 0
                    ? String(localized: "people.balance.receivable")
                    : String(localized: "people.balance.payable")
                )
                .font(Typography.font(for: .label))
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Sheet

private struct AddSheet: View {
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
                    Button(String(localized: "people.add.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "people.add.save")) {
                        Task {
                            await onSave(name.trimmed, phone.nilIfEmpty, notes.nilIfEmpty)
                        }
                    }
                    .disabled(name.trimmed.isEmpty)
                }
            }
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespaces) }
    var nilIfEmpty: String? { trimmed.isEmpty ? nil : trimmed }
}

#Preview {
    NavigationStack { PeopleListView() }
}
