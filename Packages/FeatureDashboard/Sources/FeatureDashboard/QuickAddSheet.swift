import SwiftUI
import SwiftData
import DesignSystem
import Domain
import Data
import Observability

// MARK: - Quick Add Sheet

struct QuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var amount = ""
    @State private var kind: CurrencyKind = .tryCoin
    @State private var direction: DebtDirection = .receivable
    @State private var isSaving = false
    let onDone: () async -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "quickAdd.person"), text: $name)
                        .disabled(isSaving)
                    TextField(String(localized: "quickAdd.amount"), text: $amount)
                        .keyboardType(.decimalPad)
                        .disabled(isSaving)
                }
                Section {
                    Picker(String(localized: "quickAdd.type"), selection: $kind) {
                        ForEach(CurrencyKind.allCases, id: \.self) { k in
                            Text(k.rawValue).tag(k)
                        }
                    }
                    .disabled(isSaving)
                    Picker(String(localized: "quickAdd.direction"), selection: $direction) {
                        Text(String(localized: "quickAdd.receivable")).tag(DebtDirection.receivable)
                        Text(String(localized: "quickAdd.payable")).tag(DebtDirection.payable)
                    }
                    .disabled(isSaving)
                }
            }
            .navigationTitle(String(localized: "quickAdd.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "quickAdd.cancel")) { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(String(localized: "quickAdd.save")) {
                            Task { await save() }
                        }
                        .disabled(name.trimmed.isEmpty || (Decimal(string: amount) ?? .zero) <= .zero)
                    }
                }
            }
        }
    }

    // MARK: - Save via Repository Layer

    private func save() async {
        guard let amt = Decimal(string: amount), amt > 0, !name.trimmed.isEmpty else { return }
        isSaving = true

        do {
            // Use repository layer for proper audit trail and validation
            let personRepo = PersonRepository(modelContext: modelContext)
            let debtRepo = DebtRepository(modelContext: modelContext, auditTrail: AuditTrailService(modelContainer: modelContext.container))

            let person = try await personRepo.execute(
                name: name.trimmed,
                phoneNumber: nil,
                notes: nil
            )

            try await debtRepo.execute(
                personID: person.id,
                amount: amt.rounded(scale: 2),
                kind: kind,
                direction: direction,
                note: nil,
                dueDate: nil
            )

            AnalyticsService().track(.debtAdded(kind: kind.analyticsDebtKind))
            dismiss()
            await onDone()
        } catch {
            AppLog.data.error("[QuickAdd] Save failed: \(error.localizedDescription)")
            isSaving = false
        }
    }
}

// MARK: - Helpers

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
