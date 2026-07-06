import SwiftUI
import SwiftData
import DesignSystem
import Domain

// MARK: - Person Detail View

public struct PersonDetailView: View {
    let person: Person
    let modelContext: ModelContext
    @State private var viewModel: PersonDetailViewModel?
    @State private var showAddDebt = false
    @State private var selectedDebt: DebtRecord?

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
                        let vm = PersonDetailViewModel(person: person, modelContext: modelContext)
                        viewModel = vm
                        await vm.loadData()
                    }
            }
        }
        .sheet(isPresented: $showAddDebt) {
            AddDebtSheet(person: person) { amount, kind, direction, note, dueDate in
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
            // Balance header
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: Spacing.s) {
                        Text(String(localized: "personDetail.balance.label", bundle: .module))
                            .font(Typography.font(for: .caption))
                            .foregroundColor(Color("ink400", bundle: .module))
                        Text(vm.balance.formatted())
                            .font(Typography.font(for: .display))
                            .foregroundColor(balanceColor(vm.balance))
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            // Debt timeline
            Section {
                if vm.debts.isEmpty {
                    EmptyStateView(
                        title: String(localized: "personDetail.empty.title", bundle: .module),
                        subtitle: String(localized: "personDetail.empty.subtitle", bundle: .module)
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
                Text(String(localized: "personDetail.history.title", bundle: .module))
                    .font(Typography.font(for: .headline))
                    .foregroundColor(Color("ink700", bundle: .module))
            }
        }
        .listStyle(.insetGrouped)
        .background(Color("background", bundle: .module))
        .navigationTitle(person.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddDebt = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable { await vm.loadData() }
    }

    // MARK: - Debt Row

    private func debtRow(_ debt: DebtRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(debt.note ?? debt.kind.rawValue)
                    .font(Typography.font(for: .body))
                    .foregroundColor(Color("ink900", bundle: .module))
                if let dueDate = debt.dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(Typography.font(for: .caption))
                        .foregroundColor(Color("ink400", bundle: .module))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text(debt.amount.formatted())
                    .font(Typography.font(for: .amount))
                    .foregroundColor(debt.direction == .receivable
                        ? Color("positive600", bundle: .module)
                        : Color("negative600", bundle: .module))
                Text(statusLabel(debt.status))
                    .font(Typography.font(for: .caption))
                    .foregroundColor(Color("ink400", bundle: .module))
            }
        }
    }

    // MARK: - Helpers

    private func balanceColor(_ balance: Decimal) -> Color {
        if balance.isEffectivelyZero { return Color("ink900", bundle: .module) }
        return balance > 0 ? Color("positive600", bundle: .module) : Color("negative600", bundle: .module)
    }

    private func statusLabel(_ status: DebtStatus) -> String {
        switch status {
        case .pending:
            String(localized: "personDetail.status.pending", bundle: .module)
        case .paid:
            String(localized: "personDetail.status.paid", bundle: .module)
        case .archived:
            String(localized: "personDetail.status.archived", bundle: .module)
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
    let onSave: (Decimal, CurrencyKind, DebtDirection, String?, Date?) async -> Void

    var parsedAmount: Decimal? {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        String(localized: "debt.add.amountPlaceholder", bundle: .module),
                        text: $amountText
                    )
                    .keyboardType(.decimalPad)

                    Picker(
                        String(localized: "debt.add.kind.label", bundle: .module),
                        selection: $selectedKind
                    ) {
                        ForEach(CurrencyKind.allCases, id: \.self) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }

                    Picker(
                        String(localized: "debt.add.direction.label", bundle: .module),
                        selection: $selectedDirection
                    ) {
                        Text(String(localized: "debt.add.direction.receivable", bundle: .module))
                            .tag(DebtDirection.receivable)
                        Text(String(localized: "debt.add.direction.payable", bundle: .module))
                            .tag(DebtDirection.payable)
                    }
                }

                Section {
                    TextField(
                        String(localized: "debt.add.notePlaceholder", bundle: .module),
                        text: $note
                    )
                }

                Section {
                    Toggle(
                        String(localized: "debt.add.dueDateToggle", bundle: .module),
                        isOn: $hasDueDate
                    )
                    if hasDueDate {
                        DatePicker(
                            String(localized: "debt.add.dueDatePicker", bundle: .module),
                            selection: $dueDate,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle(String(localized: "debt.add.title", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "debt.add.cancel", bundle: .module)) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "debt.add.save", bundle: .module)) {
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
                    .disabled(parsedAmount == nil || parsedAmount! <= 0)
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
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(String(localized: "payment.remainingBalance", bundle: .module))
                        Spacer()
                        Text(debt.amount.formatted())
                            .font(Typography.font(for: .amount))
                    }
                }

                Section {
                    TextField(
                        String(localized: "payment.amountPlaceholder", bundle: .module),
                        text: $amountText
                    )
                    .keyboardType(.decimalPad)

                    TextField(
                        String(localized: "payment.notePlaceholder", bundle: .module),
                        text: $note
                    )
                }
            }
            .navigationTitle(String(localized: "payment.title", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "payment.cancel", bundle: .module)) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "payment.save", bundle: .module)) {
                        guard let amount = parsedAmount, amount > 0 else { return }
                        Task {
                            await onSave(
                                amount,
                                note.isEmpty ? nil : note.trimmingCharacters(in: .whitespaces)
                            )
                        }
                    }
                    .disabled(parsedAmount == nil || parsedAmount! <= 0)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PersonDetailView(
            person: Person(name: "Ahmet"),
            modelContext: try! ModelContainer(
                for: PersonModel.self, DebtRecordModel.self, PaymentModel.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ).mainContext
        )
    }
}
