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
    @State private var searchText = ""
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
            AddPremiumSheet { name, phone, notes in
                await viewModel?.addPerson(name: name, phoneNumber: phone, notes: notes)
                showAdd = false
            }
        }
        .refreshable { await viewModel?.loadPersons() }
        .background(ColorTokens.background)
    }

    // MARK: Content

    private func content(_ vm: PeopleListViewModel) -> some View {
        VStack(spacing: 0) {
            // Premium Search Bar
            HStack(spacing: Spacing.s) {
                Image(systemName: "magnifyingglass")
                    .font(Typography.font(for: .body))
                    .foregroundStyle(ColorTokens.textTertiary)
                TextField(String(localized: "people.search.placeholder"), text: $searchText)
                    .font(Typography.font(for: .body))
                    .foregroundStyle(ColorTokens.textPrimary)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(ColorTokens.surface)
            )
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.m)

            // Premium Segment Control
            HStack(spacing: Spacing.xxs) {
                ForEach(PeopleSegment.allCases, id: \.self) { segment in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            vm.selectedSegment = segment
                        }
                    } label: {
                        Text(segment == .receivable
                            ? String(localized: "people.segment.receivable")
                            : String(localized: "people.segment.payable"))
                            .font(Typography.font(for: .buttonSmall))
                            .foregroundStyle(vm.selectedSegment == segment
                                ? (segment == .receivable ? ColorTokens.positive : ColorTokens.negative)
                                : ColorTokens.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.s)
                            .background(
                                Capsule()
                                    .fill(vm.selectedSegment == segment
                                        ? (segment == .receivable
                                            ? ColorTokens.positiveLight.opacity(0.2)
                                            : ColorTokens.negativeLight.opacity(0.2))
                                        : Color.clear)
                            )
                    }
                }
            }
            .padding(Spacing.xxs)
            .background(Capsule().fill(ColorTokens.surface))
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.m)

            // List
            let filtered = filteredPersons(from: vm)
            if filtered.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filtered) { item in
                        NavigationLink {
                            PersonDetailView(person: item.person, modelContext: modelContext)
                        } label: {
                            PersonRow(person: item.person, balance: item.balance)
                        }
                        .listRowBackground(ColorTokens.surface)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: filtered.count)
            }
        }
        .background(ColorTokens.background)
    }

    // MARK: Filtering

    private func filteredPersons(from vm: PeopleListViewModel) -> [PersonListItem] {
        let searched = vm.persons.filter { person in
            searchText.isEmpty || person.name.localizedCaseInsensitiveContains(searchText)
        }
        return searched.compactMap { person -> PersonListItem? in
            guard let balance = vm.personBalances[person.id] else { return nil }
            switch vm.selectedSegment {
            case .receivable where balance > 0:
                return PersonListItem(person: person, balance: balance)
            case .payable where balance < 0:
                return PersonListItem(person: person, balance: balance.magnitude)
            default:
                return nil
            }
        }
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            Image(systemName: "person.2.slash")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(ColorTokens.textTertiary)
            VStack(spacing: Spacing.xs) {
                Text(String(localized: "people.empty.title"))
                    .font(Typography.font(for: .headline))
                    .foregroundStyle(ColorTokens.textSecondary)
                Text(String(localized: "people.empty.subtitle"))
                    .font(Typography.font(for: .body))
                    .foregroundStyle(ColorTokens.textTertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Person Row

private struct PersonRow: View {
    let person: Person
    let balance: Decimal

    var body: some View {
        HStack(spacing: Spacing.m) {
            AvatarView(name: person.name, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(Typography.font(for: .bodyEmphasis))
                    .foregroundStyle(ColorTokens.textPrimary)
                if let phone = person.phoneNumber {
                    Text(phone)
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textTertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(balance.formatted())
                    .font(Typography.font(for: .amount))
                    .foregroundStyle(balance >= 0 ? ColorTokens.positive : ColorTokens.negative)
                    .contentTransition(.numericText())
                Text(balance >= 0
                    ? String(localized: "people.balance.receivable")
                    : String(localized: "people.balance.payable"))
                    .font(Typography.font(for: .label))
                    .foregroundStyle(ColorTokens.textTertiary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Person List Item

private struct PersonListItem: Identifiable {
    let person: Person
    let balance: Decimal
    var id: UUID { person.id }
}

// MARK: - Premium Add Sheet

private struct AddPremiumSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var notes = ""
    @State private var isSaving = false
    let onSave: (String, String?, String?) async -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                // Avatar preview
                ZStack {
                    Circle()
                        .fill(ColorTokens.accent.opacity(0.1))
                        .frame(width: 80, height: 80)
                    if name.isEmpty {
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(ColorTokens.accent)
                    } else {
                        Text(name.prefix(2).uppercased())
                            .font(Typography.font(for: .title))
                            .foregroundStyle(ColorTokens.accent)
                    }
                }
                .padding(.top, Spacing.xl)

                VStack(spacing: Spacing.m) {
                    PremiumTextField(
                        icon: "person.fill",
                        placeholder: String(localized: "people.add.namePlaceholder"),
                        text: $name
                    )
                    PremiumTextField(
                        icon: "phone.fill",
                        placeholder: String(localized: "people.add.phonePlaceholder"),
                        text: $phone
                    )
                    PremiumTextField(
                        icon: "note.text",
                        placeholder: String(localized: "people.add.notesPlaceholder"),
                        text: $notes
                    )
                }
                .padding(.horizontal, Spacing.xl)

                Spacer()

                // Save button
                Button {
                    Task { await save() }
                } label: {
                    HStack(spacing: Spacing.s) {
                        if isSaving {
                            ProgressView()
                                .tint(.black)
                        }
                        Text(String(localized: "people.add.save"))
                            .font(Typography.font(for: .button))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        Capsule()
                            .fill(name.trimmed.isEmpty || isSaving
                                ? ColorTokens.border
                                : ColorTokens.accent)
                    )
                    .foregroundStyle(name.trimmed.isEmpty || isSaving
                        ? ColorTokens.textTertiary
                        : .black)
                }
                .disabled(name.trimmed.isEmpty || isSaving)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(ColorTokens.background)
            .navigationTitle(String(localized: "people.add.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "people.add.cancel")) { dismiss() }
                        .disabled(isSaving)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        await onSave(
            name.trimmed,
            phone.trimmed.isEmpty ? nil : phone.trimmed,
            notes.trimmed.isEmpty ? nil : notes.trimmed
        )
        isSaving = false
    }
}

// MARK: - Premium Text Field

private struct PremiumTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(ColorTokens.textTertiary)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .font(Typography.font(for: .body))
                .foregroundStyle(ColorTokens.textPrimary)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.ml)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(ColorTokens.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(ColorTokens.border, lineWidth: 1)
        )
    }
}

// MARK: - Helpers

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

// MARK: - Preview

#Preview {
    NavigationStack { PeopleListView() }
}
