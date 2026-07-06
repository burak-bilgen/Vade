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
                        Text(String(localized: "personDetail.balance.label"))
                            .font(Typography.font(for: .caption))
                            .foregroundColor(Color("ink400"))
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
                    .foregroundColor(Color("ink700"))
            }
        }
        .listStyle(.insetGrouped)
        .background(Color("background"))
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
                    .foregroundColor(Color("ink900"))
                if let dueDate = debt.dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(Typography.font(for: .caption))
                        .foregroundColor(Color("ink400"))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text(debt.amount.formatted())
                    .font(Typography.font(for: .amount))
                    .foregroundColor(debt.direction == .receivable
                        ? Color("positive600")
                        : Color("negative600"))
                Text(statusLabel(debt.status))
                    .font(Typography.font(for: .caption))
                    .foregroundColor(Color("ink400"))
            }
        }
    }

    // MARK: - Helpers

    private func balanceColor(_ balance: Decimal) -> Color {
        if balance.isEffectivelyZero { return Color("ink900") }
        return balance > 0 ? Color("positive600") : Color("negative600")
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
    let onSave: (Decimal, CurrencyKind, DebtDirection, String?, Date?) async -> Void

    var parsedAmount: Decimal? {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        String(localized: "debt.add.amountPlaceholder"),
                        text: $amountText
                    )
                    .keyboardType(.decimalPad)

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
            .navigationBarTitleDisplayMode(.inline)
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
                    .keyboardType(.decimalPad)

                    TextField(
                        String(localized: "payment.notePlaceholder"),
                        text: $note
                    )
                }
            }
            .navigationTitle(String(localized: "payment.title"))
            .navigationBarTitleDisplayMode(.inline)
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
