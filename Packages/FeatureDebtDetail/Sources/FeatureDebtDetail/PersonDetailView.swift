import SwiftUI
import SwiftData
import DesignSystem
import Domain
import Data
import Observability

// MARK: - Person Detail View

public struct PersonDetailView: View {
    let person: Person
    let modelContext: ModelContext
    @State private var viewModel: PersonDetailViewModel?
    @State private var showAddDebt = false
    @State private var selectedDebt: DebtRecord?
    @State private var analytics: any AnalyticsTracking = AnalyticsService()

    public init(person: Person, modelContext: ModelContext) {
        self.person = person
        self.modelContext = modelContext
    }

    public var body: some View {
        Group {
            if let vm = viewModel {
                contentView(vm)
            } else {
                ProgressView()
                    .task {
                        let vm = PersonDetailViewModel(person: person, modelContext: modelContext, analytics: analytics)
                        viewModel = vm
                        await vm.loadData()
                    }
            }
        }
        .sheet(isPresented: $showAddDebt) {
            AddDebtSheet(person: person, analytics: analytics) { amount, kind, direction, note, dueDate in
                await viewModel?.addDebt(amount: amount, kind: kind, direction: direction, note: note, dueDate: dueDate)
                showAddDebt = false
            }
        }
        .sheet(item: $selectedDebt) { debt in
            RecordPaymentSheet(debt: debt) { amount, note in
                await viewModel?.recordPayment(debtRecordID: debt.id, amount: amount, note: note)
                selectedDebt = nil
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func contentView(_ vm: PersonDetailViewModel) -> some View {
        List {
            // Balance header — modern card style
            Section {
                VStack(spacing: Spacing.s) {
                    Text(String(localized: "personDetail.balance.label"))
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textTertiary)
                        .textCase(.uppercase)
                    Text(vm.balance.formatted())
                        .font(Typography.font(for: .display))
                        .foregroundStyle(balanceColor(vm.balance))
                        .minimumScaleFactor(0.85)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.xl)
                .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ColorTokens.surface))
                .overlay(RoundedRectangle(cornerRadius: Radius.lg).stroke(ColorTokens.border, lineWidth: 1))
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "personDetail.balance.accessibility"))
            }

            // Debt timeline
            Section {
                if vm.debts.isEmpty {
                    EmptyStateView(
                        title: String(localized: "personDetail.empty.title"),
                        subtitle: String(localized: "personDetail.empty.subtitle")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(vm.debts) { debt in
                        debtRow(debt)
                            .onTapGesture {
                                if debt.status == .pending {
                                    selectedDebt = debt
                                }
                            }
                    }
                }
            } header: {
                Text(String(localized: "personDetail.history.title"))
                    .font(Typography.font(for: .headline))
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .background(ColorTokens.background)
        .navigationTitle(person.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddDebt = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(String(localized: "personDetail.addDebt.button"))
            }
        }
        .refreshable { await vm.loadData() }
    }

    // MARK: - Debt Row

    private func debtRow(_ debt: DebtRecord) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(debt.note ?? debt.kind.rawValue)
                    .font(Typography.font(for: .body))
                    .foregroundStyle(ColorTokens.textPrimary)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
                if let dueDate = debt.dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textTertiary)
                        .minimumScaleFactor(0.85)
                }
            }
            Spacer(minLength: Spacing.m)
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text(debt.amount.formatted())
                    .font(Typography.font(for: .amount))
                    .foregroundStyle(debt.direction == .receivable
                        ? ColorTokens.positive
                        : ColorTokens.negative)
                    .minimumScaleFactor(0.85)
                Text(statusLabel(debt.status))
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(ColorTokens.textTertiary)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }

    // MARK: - Helpers

    private func balanceColor(_ balance: Decimal) -> Color {
        if balance.isEffectivelyZero { return ColorTokens.textPrimary }
        return balance > 0 ? ColorTokens.positive : ColorTokens.negative
    }

    private func statusLabel(_ status: DebtStatus) -> String {
        switch status {
        case .pending:
            String(localized: "personDetail.status.pending")
        case .paid:
            String(localized: "personDetail.status.paid")
        case .archived:
            String(localized: "personDetail.status.archived")
        }
    }
}

// MARK: - Add Debt Sheet

private struct AddDebtSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    @State private var selectedKind: CurrencyKind = .tryCoin
    @State private var selectedDirection: DebtDirection = .receivable
    @State private var note = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()

    let person: Person
    let analytics: any AnalyticsTracking
    let onSave: (Decimal, CurrencyKind, DebtDirection, String?, Date?) async -> Void

    var parsedAmount: Decimal? {
        Decimal(string: amountText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        String(localized: "debt.add.amountPlaceholder"),
                        text: $amountText
                    )
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif

                    Picker(
                        String(localized: "debt.add.kind.label"),
                        selection: $selectedKind
                    ) {
                        ForEach(CurrencyKind.allCases, id: \.self) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }

                    Picker(
                        String(localized: "debt.add.direction.label"),
                        selection: $selectedDirection
                    ) {
                        Text(String(localized: "debt.add.direction.receivable"))
                            .tag(DebtDirection.receivable)
                        Text(String(localized: "debt.add.direction.payable"))
                            .tag(DebtDirection.payable)
                    }
                }

                Section {
                    TextField(
                        String(localized: "debt.add.notePlaceholder"),
                        text: $note
                    )
                }

                Section {
                    Toggle(
                        String(localized: "debt.add.dueDateToggle"),
                        isOn: $hasDueDate
                    )
                    if hasDueDate {
                        DatePicker(
                            String(localized: "debt.add.dueDatePicker"),
                            selection: $dueDate,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle(String(localized: "debt.add.title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onChange(of: selectedKind) { _, newKind in
                analytics.track(.currencyChanged(to: newKind.analyticsCode))
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "debt.add.cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "debt.add.save")) {
                        guard let amount = parsedAmount, amount > 0 else { return }
                        Task {
                            await onSave(
                                amount,
                                selectedKind,
                                selectedDirection,
                                note.isEmpty ? nil : note.trimmingCharacters(in: .whitespaces),
                                hasDueDate ? dueDate : nil
                            )
                        }
                    }
                    .disabled(!(parsedAmount.map { $0 > 0 } ?? false))
                }
            }
        }
    }
}

// MARK: - Record Payment Sheet

private struct RecordPaymentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    @State private var note = ""

    let debt: DebtRecord
    let onSave: (Decimal, String?) async -> Void

    var parsedAmount: Decimal? {
        Decimal(string: amountText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(String(localized: "payment.remainingBalance"))
                        Spacer()
                        Text(debt.amount.formatted())
                            .font(Typography.font(for: .amount))
                    }
                }

                Section {
                    TextField(
                        String(localized: "payment.amountPlaceholder"),
                        text: $amountText
                    )
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif

                    TextField(
                        String(localized: "payment.notePlaceholder"),
                        text: $note
                    )
                }
            }
            .navigationTitle(String(localized: "payment.title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "payment.cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "payment.save")) {
                        guard let amount = parsedAmount, amount > 0 else { return }
                        Task {
                            await onSave(
                                amount,
                                note.isEmpty ? nil : note.trimmingCharacters(in: .whitespaces)
                            )
                        }
                    }
                    .disabled(!(parsedAmount.map { $0 > 0 } ?? false))
                }
            }
        }
    }
}

#if DEBUG
private let previewModelContainer: ModelContainer? = {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    do {
        return try ModelContainer(for: PersonModel.self, DebtRecordModel.self, PaymentModel.self, configurations: config)
    } catch {
        print("Failed to create preview ModelContainer: \(error.localizedDescription)")
        return nil
    }
}()

#Preview {
    NavigationStack {
        if let container = previewModelContainer {
            PersonDetailView(
                person: Person(name: "Ahmet"),
                modelContext: container.mainContext
            )
        } else {
            Text("Preview container could not be created")
                .foregroundStyle(ColorTokens.textTertiary)
        }
    }
}
#endif
