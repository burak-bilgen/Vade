import SwiftUI
import DesignSystem
import Domain
import Core

// MARK: - Quick Add ViewModel

@MainActor
@Observable
final class QuickAddViewModel {
    var name = ""
    var amount = ""
    var kind: CurrencyKind = .tryCoin
    var direction: DebtDirection = .receivable
    var isSaving = false
    var errorMessage: String?

    private let personRepo: AddPersonUseCase
    private let debtRepo: AddDebtUseCase
    private let analytics: any AnalyticsTracking
    let onDone: () async -> Void

    init(
        personRepo: AddPersonUseCase,
        debtRepo: AddDebtUseCase,
        analytics: any AnalyticsTracking = AnalyticsService.shared,
        onDone: @escaping () async -> Void
    ) {
        self.personRepo = personRepo
        self.debtRepo = debtRepo
        self.analytics = analytics
        self.onDone = onDone
    }

    var canSave: Bool {
        !name.trimmed.isEmpty && (Decimal(string: amount) ?? .zero) > 0
    }

    func save() async -> Bool {
        guard var amt = Decimal(string: amount), amt > 0, !name.trimmed.isEmpty else { return false }
        isSaving = true
        errorMessage = nil

        do {
            let person = try await personRepo.execute(
                name: name.trimmed,
                phoneNumber: nil,
                notes: nil
            )

            var rounded = Decimal()
            NSDecimalRound(&rounded, &amt, 2, .plain)
            _ = try await debtRepo.execute(
                personID: person.id,
                amount: rounded,
                kind: kind,
                direction: direction,
                note: nil,
                dueDate: nil
            )

            analytics.track(.debtAdded(kind: kind.analyticsDebtKind))
            isSaving = false
            return true
        } catch {
            AppLog.data.error("[QuickAdd] Save failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isSaving = false
            return false
        }
    }
}

// MARK: - Quick Add Sheet

struct QuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: QuickAddViewModel?
    let personRepo: AddPersonUseCase
    let debtRepo: AddDebtUseCase
    let onDone: () async -> Void

    var body: some View {
        NavigationStack {
            if let vm = viewModel {
                quickAddForm(vm)
            }
        }
        .onAppear {
            viewModel = QuickAddViewModel(
                personRepo: personRepo,
                debtRepo: debtRepo,
                onDone: onDone
            )
        }
    }

    private func quickAddForm(_ vm: QuickAddViewModel) -> some View {
        Form {
            Section {
                TextField(String(localized: "quickAdd.person"), text: Binding(
                    get: { vm.name },
                    set: { vm.name = $0 }
                ))
                .disabled(vm.isSaving)
                TextField(String(localized: "quickAdd.amount"), text: Binding(
                    get: { vm.amount },
                    set: { vm.amount = $0 }
                ))
                #if !os(macOS)
                .keyboardType(.decimalPad)
                #endif
                .disabled(vm.isSaving)
            }
            Section {
                Picker(String(localized: "quickAdd.type"), selection: Binding(
                    get: { vm.kind },
                    set: { vm.kind = $0 }
                )) {
                    ForEach(CurrencyKind.allCases, id: \.self) { k in
                        Text(k.rawValue).tag(k)
                    }
                }
                .disabled(vm.isSaving)
                Picker(String(localized: "quickAdd.direction"), selection: Binding(
                    get: { vm.direction },
                    set: { vm.direction = $0 }
                )) {
                    Text(String(localized: "quickAdd.receivable")).tag(DebtDirection.receivable)
                    Text(String(localized: "quickAdd.payable")).tag(DebtDirection.payable)
                }
                .disabled(vm.isSaving)
            }

            if let error = vm.errorMessage {
                Section {
                    Text(error)
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.negative)
                }
            }
        }
        .navigationTitle(String(localized: "quickAdd.title"))
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .scrollContentBackground(.hidden)
        .background(ColorTokens.background)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "quickAdd.cancel")) { dismiss() }
                    .disabled(vm.isSaving)
            }
            ToolbarItem(placement: .confirmationAction) {
                if vm.isSaving {
                    ProgressView()
                } else {
                    Button(String(localized: "quickAdd.save")) {
                        Task {
                            let success = await vm.save()
                            if success {
                                await vm.onDone()
                                dismiss()
                            }
                        }
                    }
                    .disabled(!vm.canSave)
                }
            }
        }
    }
}

// MARK: - Helpers

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
