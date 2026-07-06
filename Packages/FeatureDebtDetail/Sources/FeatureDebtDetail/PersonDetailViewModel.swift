import Foundation
import SwiftData
import Domain
import Core
import Data
import Observability

// MARK: - Person Detail ViewModel

@MainActor
@Observable
public final class PersonDetailViewModel {
    public var debts: [DebtRecord] = []
    public var balance: Decimal = .zero
    public var isLoading = false

    let person: Person
    private let modelContext: ModelContext
    private let debtRepo: DebtRepository
    private let balanceRepo: BalanceRepository
    private let paymentRepo: PaymentRepository
    private let analytics: any AnalyticsTracking
    private let notificationService: NotificationScheduling?

    public init(
        person: Person,
        modelContext: ModelContext,
        analytics: any AnalyticsTracking = AnalyticsService(),
        notificationService: NotificationScheduling? = nil
    ) {
        self.person = person
        self.modelContext = modelContext
        self.analytics = analytics
        self.notificationService = notificationService
        let auditTrail = AuditTrailService(modelContainer: modelContext.container)
        self.debtRepo = DebtRepository(modelContext: modelContext, auditTrail: auditTrail)
        self.balanceRepo = BalanceRepository(modelContext: modelContext)
        self.paymentRepo = PaymentRepository(modelContext: modelContext, auditTrail: auditTrail)
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
            let record = try await debtRepo.execute(
                personID: person.id,
                amount: amount,
                kind: kind,
                direction: direction,
                note: note,
                dueDate: dueDate
            )
            analytics.track(.debtAdded(kind: kind.analyticsDebtKind))
            if let dueDate = dueDate {
                await notificationService?.scheduleReminder(
                    for: record.id,
                    personName: person.name,
                    amount: amount,
                    dueDate: dueDate
                )
            }
            await loadData()
        } catch {
            AppLog.data.error("[PersonDetailViewModel] Add debt failed: \(error.localizedDescription)")
        }
    }

    public func recordPayment(debtRecordID: UUID, amount: Decimal, note: String?) async {
        do {
            _ = try await paymentRepo.execute(debtRecordID: debtRecordID, amount: amount, note: note)
            // Determine payment type by matching against the debt's remaining balance
            let paymentType: PaymentType = {
                if let debt = debts.first(where: { $0.id == debtRecordID }) {
                    return amount >= debt.amount ? .full : .partial
                }
                return .partial
            }()
            analytics.track(.paymentRecorded(type: paymentType))
            await loadData()
            if await isDebtFullyPaid(debtRecordID) {
                await notificationService?.cancelReminder(for: debtRecordID)
            }
        } catch {
            AppLog.data.error("[PersonDetailViewModel] Payment failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func isDebtFullyPaid(_ debtRecordID: UUID) async -> Bool {
        guard let debt = debts.first(where: { $0.id == debtRecordID }) else { return false }
        let descriptor = FetchDescriptor<PaymentModel>(
            predicate: #Predicate { $0.debtRecordID == debtRecordID }
        )
        guard let payments = try? modelContext.fetch(descriptor) else { return false }
        let totalPaid = payments.reduce(Decimal.zero) { $0 + $1.amount }
        return totalPaid >= debt.amount
    }
}
