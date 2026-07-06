import Foundation
import SwiftData
import Domain
import Core
import Data

// MARK: - Person Detail ViewModel

@MainActor
@Observable
public final class PersonDetailViewModel {
    public var debts: [DebtRecord] = []
    public var balance: Decimal = .zero
    public var isLoading = false

    let person: Person
    private let debtRepo: DebtRepository
    private let balanceRepo: BalanceRepository
    private let paymentRepo: PaymentRepository

    public init(person: Person, modelContext: ModelContext) {
        self.person = person
        self.debtRepo = DebtRepository(modelContext: modelContext)
        self.balanceRepo = BalanceRepository(modelContext: modelContext)
        self.paymentRepo = PaymentRepository(modelContext: modelContext)
    }

    public func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            debts = try await debtRepo.execute(for: person.id)
            balance = try await balanceRepo.execute(for: person.id)
        } catch {
            AppLog.data.error("[PersonDetailViewModel] Load failed: \(error.localizedDescription)")
        }
    }

    public func addDebt(
        amount: Decimal,
        kind: CurrencyKind,
        direction: DebtDirection,
        note: String?,
        dueDate: Date?
    ) async {
        do {
            _ = try await debtRepo.execute(
                personID: person.id,
                amount: amount,
                kind: kind,
                direction: direction,
                note: note,
                dueDate: dueDate
            )
            await loadData()
        } catch {
            AppLog.data.error("[PersonDetailViewModel] Add debt failed: \(error.localizedDescription)")
        }
    }

    public func recordPayment(debtRecordID: UUID, amount: Decimal, note: String?) async {
        do {
            _ = try await paymentRepo.execute(debtRecordID: debtRecordID, amount: amount, note: note)
            await loadData()
        } catch {
            AppLog.data.error("[PersonDetailViewModel] Payment failed: \(error.localizedDescription)")
        }
    }
}
