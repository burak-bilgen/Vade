import Foundation
import Domain
import Core
import Observability
import Networking

// MARK: - Person Detail ViewModel

@MainActor
@Observable
public final class PersonDetailViewModel {
    public private(set) var debts: [DebtRecord] = []
    public private(set) var balance: Decimal = .zero
    public private(set) var displayCurrency: CurrencyKind = .tryCoin
    public private(set) var isLoading = false

    let person: Person
    private let debtRepo: AddDebtUseCase & FetchDebtsForPersonUseCase
    private let balanceRepo: CalculateBalanceUseCase
    private let paymentRepo: RecordPaymentUseCase & FetchPaymentsForDebtUseCase
    private let rateClient: any ExchangeRateProviding
    private let analytics: any AnalyticsTracking
    private let notificationService: NotificationScheduling?

    public init(
        person: Person,
        debtRepo: AddDebtUseCase & FetchDebtsForPersonUseCase,
        balanceRepo: CalculateBalanceUseCase,
        paymentRepo: RecordPaymentUseCase & FetchPaymentsForDebtUseCase,
        rateClient: any ExchangeRateProviding = ExchangeRateClient(),
        analytics: any AnalyticsTracking = AnalyticsService.shared,
        notificationService: NotificationScheduling? = nil
    ) {
        self.person = person
        self.debtRepo = debtRepo
        self.balanceRepo = balanceRepo
        self.paymentRepo = paymentRepo
        self.rateClient = rateClient
        self.analytics = analytics
        self.notificationService = notificationService
    }

    public func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            debts = try await debtRepo.execute(for: person.id)
            let rawBalance = try await balanceRepo.execute(for: person.id)
            
            let saved = UserDefaults.standard.string(forKey: UserDefaultsKeys.preferredCurrency) ?? CurrencyKind.tryCoin.rawValue
            let preferred = CurrencyKind(rawValue: saved) ?? .tryCoin
            displayCurrency = preferred
            
            var rate: Decimal = 1
            if preferred != .tryCoin {
                let converter = CurrencyConverter(rateProvider: rateClient)
                if let r = try? await converter.convertToTRY(amount: 1, from: preferred), r > 0 {
                    rate = r
                }
            }
            balance = rawBalance / rate
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
        guard let payments = try? await paymentRepo.execute(for: debtRecordID) else { return false }
        let totalPaid = payments.reduce(Decimal.zero) { $0 + $1.amount }
        return totalPaid >= debt.amount
    }
}
