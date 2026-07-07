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
                    .entrance(.fade)
                    .task {
                        let personRepo = PersonRepository(modelContext: modelContext)
                        let debtRepo = DebtRepository(modelContext: modelContext)
                        let balanceRepo = BalanceRepository(modelContext: modelContext)
                        let vm = PeopleListViewModel(
                            personRepo: personRepo,
                            balanceRepo: balanceRepo,
                            debtRepo: debtRepo,
                            analytics: analytics
                        )
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
                .premiumPress()
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
                            .symbolEffect(.bounce.up, value: searchText)
                    }
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(ColorTokens.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(!searchText.isEmpty ? ColorTokens.accent : ColorTokens.border, lineWidth: 1)
                    .animation(.easeInOut(duration: 0.2), value: !searchText.isEmpty)
            )
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.m)
            .entrance(.up, delay: 0.1)

            // Premium Segment Control
            HStack(spacing: Spacing.xxs) {
                ForEach(PeopleSegment.allCases, id: \.self) { segment in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            vm.selectedSegment = segment
                        }
                    } label: {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: segment == .receivable
                                ? "arrow.down.left.circle.fill"
                                : "arrow.up.right.circle.fill")
                                .font(.system(size: 12))
                            Text(segment == .receivable
                                ? String(localized: "people.segment.receivable")
                                : String(localized: "people.segment.payable"))
                                .font(Typography.font(for: .buttonSmall))
                        }
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
                        .contentShape(.capsule)
                    }
                    .premiumPress(scale: 0.92)
                }
            }
            .padding(Spacing.xxs)
            .background(Capsule().fill(ColorTokens.surface))
            .overlay(
                Capsule()
                    .stroke(ColorTokens.border, lineWidth: 0.5)
            )
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.m)
            .entrance(.up, delay: 0.15)

            // List
            let filtered = filteredPersons(from: vm)
            if filtered.isEmpty {
                enhancedEmptyState(segment: vm.selectedSegment)
                    .entrance(.fade)
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.s) {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { i, item in
                            NavigationLink {
                                PersonDetailView(person: item.person, modelContext: modelContext)
                            } label: {
                                PersonCard(person: item.person, balance: item.balance)
                                    .entrance(.leading, delay: Double(i) * 0.04, duration: 0.35)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.xxs)
                }
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

    // MARK: Enhanced Empty State

    private func enhancedEmptyState(segment: PeopleSegment) -> some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(segment == .receivable
                        ? ColorTokens.positive.opacity(0.08)
                        : ColorTokens.negative.opacity(0.08))
                    .frame(width: 100, height: 100)

                Circle()
                    .stroke(segment == .receivable
                        ? ColorTokens.positive.opacity(0.2)
                        : ColorTokens.negative.opacity(0.2),
                        lineWidth: 2)
                    .frame(width: 80, height: 80)

                Image(systemName: segment == .receivable
                    ? "arrow.down.left.circle.fill"
                    : "arrow.up.right.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(segment == .receivable
                        ? ColorTokens.positive
                        : ColorTokens.negative)
            }

            VStack(spacing: Spacing.xs) {
                Text(segment == .receivable
                    ? String(localized: "people.empty.receivable.title")
                    : String(localized: "people.empty.payable.title"))
                    .font(Typography.font(for: .headline))
                    .foregroundStyle(ColorTokens.textSecondary)

                Text(segment == .receivable
                    ? String(localized: "people.empty.receivable.subtitle")
                    : String(localized: "people.empty.payable.subtitle"))
                    .font(Typography.font(for: .body))
                    .foregroundStyle(ColorTokens.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xxl)
            }

            Button {
                showAdd = true
            } label: {
                HStack(spacing: Spacing.s) {
                    Image(systemName: "person.badge.plus")
                    Text(String(localized: "people.empty.addButton"))
                        .font(Typography.font(for: .buttonSmall))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.m)
                .background(
                    Capsule()
                        .fill(ColorTokens.accent)
                )
            }
            .premiumPress()

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Person Card

private struct PersonCard: View {
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

            VStack(alignment: .trailing, spacing: 4) {
                Text(balance.formatted())
                    .font(Typography.font(for: .amount))
                    .foregroundStyle(balance >= 0 ? ColorTokens.positive : ColorTokens.negative)
                    .contentTransition(.numericText())

                // Direction badge
                HStack(spacing: 3) {
                    Image(systemName: balance >= 0
                        ? "arrow.down.left"
                        : "arrow.up.right")
                        .font(.system(size: 8, weight: .bold))
                    Text(balance >= 0
                        ? String(localized: "people.balance.receivable")
                        : String(localized: "people.balance.payable"))
                        .font(Typography.font(for: .label))
                }
                .foregroundStyle(balance >= 0 ? ColorTokens.positive : ColorTokens.negative)
                .padding(.horizontal, Spacing.s)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(balance >= 0
                            ? ColorTokens.positiveLight.opacity(0.2)
                            : ColorTokens.negativeLight.opacity(0.2))
                )
            }
        }
        .padding(Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(ColorTokens.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(ColorTokens.border, lineWidth: 0.5)
        )            .overlay(
                // Left accent bar
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(balance >= 0 ? ColorTokens.positive : ColorTokens.negative)
                    .frame(width: 3)
                    .padding(.vertical, 8),
                alignment: .leading
            )
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
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
