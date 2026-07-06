import Foundation

// MARK: - Person Use Cases

public protocol AddPersonUseCase {
    func execute(name: String, phoneNumber: String?, notes: String?) async throws -> Person
}

public protocol FetchPersonsUseCase {
    func execute(includeArchived: Bool) async throws -> [Person]
}

// MARK: - Debt Use Cases

public protocol AddDebtUseCase {
    func execute(
        personID: UUID,
        amount: Decimal,
        kind: CurrencyKind,
        direction: DebtDirection,
        note: String?,
        dueDate: Date?
    ) async throws -> DebtRecord
}

public protocol RecordPaymentUseCase {
    func execute(debtRecordID: UUID, amount: Decimal, note: String?) async throws -> Payment
}

public protocol CalculateBalanceUseCase {
    func execute(for personID: UUID) async throws -> Decimal
    func netBalance() async throws -> Decimal
}

// MARK: - Analytics

public protocol AnalyticsTracking: Sendable {
    func track(_ event: AnalyticsEvent)
}
