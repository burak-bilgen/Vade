import SwiftUI
import DesignSystem
import Domain
import Core
import Observability

// Preview disabled: requires repository injection.
public struct PeopleListView: View {
    @State private var viewModel: PeopleListViewModel?
    @State private var showAdd = false
    @State private var searchText = ""
    @Namespace private var segmentAnimation
    private let analytics: any AnalyticsTracking = AnalyticsService.shared

    private let personRepo: AddPersonUseCase & FetchPersonsUseCase
    private let debtRepo: FetchDebtsForPersonUseCase
    private let balanceRepo: CalculateBalanceUseCase
    private let paymentRepo: RecordPaymentUseCase & FetchPaymentsForDebtUseCase

    public init(
        personRepo: AddPersonUseCase & FetchPersonsUseCase,
        debtRepo: FetchDebtsForPersonUseCase,
        balanceRepo: CalculateBalanceUseCase,
        paymentRepo: RecordPaymentUseCase & FetchPaymentsForDebtUseCase
    ) {
        self.personRepo = personRepo
        self.debtRepo = debtRepo
        self.balanceRepo = balanceRepo
        self.paymentRepo = paymentRepo
    }

    public var body: some View {
        ZStack {
            FinanceBackgroundAnimation()
                .ignoresSafeArea()
            ColorTokens.background.opacity(0.12).ignoresSafeArea()

            Group {
                if let vm = viewModel {
                    content(vm)
                } else {
                    PeopleListSkeleton()
                        .entrance(.fade)
                        .task {
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
        }
        .navigationTitle(String(localized: "tab.people"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    HapticFeedback.impact(.light)
                    showAdd = true
                }) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(ColorTokens.accent))
                        .shadow(color: ColorTokens.accent.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
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
    }

    // MARK: Content

    private func content(_ vm: PeopleListViewModel) -> some View {
        VStack(spacing: 0) {
            // Premium Search Bar (Glassmorphic)
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
                    .stroke(!searchText.isEmpty ? ColorTokens.accent.opacity(0.5) : ColorTokens.border, lineWidth: 0.5)
                    .animation(.easeInOut(duration: 0.2), value: !searchText.isEmpty)
            )
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.m)
            .entrance(.up, delay: 0.1)

            // Premium Segment Control (With smooth sliding indicator animation)
            HStack(spacing: Spacing.xxs) {
                ForEach(PeopleSegment.allCases, id: \.self) { segment in
                    Button {
                        HapticFeedback.impact(.light)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
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
                        .background {
                            if vm.selectedSegment == segment {
                                Capsule()
                                    .fill(segment == .receivable
                                        ? ColorTokens.positiveLight.opacity(0.18)
                                        : ColorTokens.negativeLight.opacity(0.18))
                                    .matchedGeometryEffect(id: "activeSegment", in: segmentAnimation)
                            }
                        }
                        .contentShape(.capsule)
                    }
                    .buttonStyle(.plain)
                    .premiumPress(scale: 0.94)
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
                            NavigationLink(value: item.person) {
                                PersonCard(person: item.person, balance: item.balance, currency: vm.displayCurrency)
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
                        ? ColorTokens.positive.opacity(0.18)
                        : ColorTokens.negative.opacity(0.18),
                        lineWidth: 1.5)
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
                HapticFeedback.impact(.light)
                showAdd = true
            } label: {
                HStack(spacing: Spacing.s) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 14, weight: .bold))
                    Text(String(localized: "people.empty.addButton"))
                        .font(Typography.font(for: .buttonSmall))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.m)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [ColorTokens.accent, ColorTokens.accent.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: ColorTokens.accent.opacity(0.25), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)
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
    let currency: CurrencyKind

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

            HStack(spacing: Spacing.m) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(currency.format(balance))
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
                    .padding(.vertical, Spacing.xxxs)
                    .background(
                        Capsule()
                            .fill(balance >= 0
                                ? ColorTokens.positiveLight.opacity(0.2)
                                : ColorTokens.negativeLight.opacity(0.2))
                    )
                }
                
                // Chevron hint to prompt navigation
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(ColorTokens.textTertiary)
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
        )
        .overlay(
            // Left accent bar
            RoundedRectangle(cornerRadius: 1.5)
                .fill(balance >= 0 ? ColorTokens.positive : ColorTokens.negative)
                .frame(width: 3)
                .padding(.vertical, Spacing.s),
            alignment: .leading
        )
        .accessibilityElement(children: .combine)
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
                                .tint(.white)
                        }
                        Text(String(localized: "people.add.save"))
                            .font(Typography.font(for: .button))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: Spacing.massive)
                    .background(
                        Capsule()
                            .fill(name.trimmed.isEmpty || isSaving
                                ? ColorTokens.border
                                : ColorTokens.accent)
                    )
                    .foregroundStyle(name.trimmed.isEmpty || isSaving
                        ? ColorTokens.textSecondary
                        : .white)
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

// MARK: - People List Loading Skeleton

private struct PeopleListSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            // Search bar skeleton
            ShimmerView(cornerRadius: Radius.md)
                .frame(height: 44)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.m)

            // Segment skeleton
            ShimmerView(cornerRadius: Radius.pill)
                .frame(height: 40)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.m)

            // Person cards skeleton
            ScrollView {
                LazyVStack(spacing: Spacing.s) {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonCard(lines: 2)
                            .padding(.horizontal, Spacing.xl)
                    }
                }
                .padding(.top, Spacing.xxs)
            }
        }
    }
}

// MARK: - Helpers

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
