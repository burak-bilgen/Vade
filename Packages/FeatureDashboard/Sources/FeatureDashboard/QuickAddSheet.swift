import SwiftUI
import SwiftData
import DesignSystem
import Domain
import Data

// MARK: - Quick Add Sheet

struct QuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var amount = ""
    @State private var kind: CurrencyKind = .tryCoin
    @State private var direction: DebtDirection = .receivable
    let onDone: () async -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "quickAdd.person"), text: $name)
                    TextField(String(localized: "quickAdd.amount"), text: $amount)
                        .keyboardType(.decimalPad)
                }
                Section {
                    Picker(String(localized: "quickAdd.type"), selection: $kind) {
                        ForEach(CurrencyKind.allCases, id: \.self) { k in
                            Text(k.rawValue).tag(k)
                        }
                    }
                    Picker(String(localized: "quickAdd.direction"), selection: $direction) {
                        Text(String(localized: "quickAdd.receivable")).tag(DebtDirection.receivable)
                        Text(String(localized: "quickAdd.payable")).tag(DebtDirection.payable)
                    }
                }
            }
            .navigationTitle(String(localized: "quickAdd.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "quickAdd.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "quickAdd.save")) {
                        guard !name.isEmpty, let amt = Decimal(string: amount), amt > 0 else { return }
                        let model = PersonModel(name: name, phoneNumber: nil, notes: nil)
                        modelContext.insert(model)
                        let debt = DebtRecordModel(personID: model.id, amount: amt,
                                                     kindRawValue: kind.rawValue,
                                                     directionRawValue: direction == .receivable ? "receivable" : "payable")
                        modelContext.insert(debt)
                        try? modelContext.save()
                        dismiss()
                        Task { await onDone() }
                    }
                    .disabled(name.isEmpty || (Decimal(string: amount) ?? .zero) <= .zero)
                }
            }
        }
    }
}
