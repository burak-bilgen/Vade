import Foundation

// MARK: - Person Use Cases

@MainActor
public protocol AddPersonUseCase {
    func execute(name: String, phoneNumber: String?, notes: String?) async throws -> Person
}

@MainActor
public protocol FetchPersonsUseCase {
    func execute(includeArchived: Bool) async throws -> [Person]
}

@MainActor
public protocol UpdatePersonUseCase {
    func execute(personID: UUID, name: String, phoneNumber: String?, notes: String?) async throws -> Person
}

@MainActor
public protocol DeletePersonUseCase {
    func execute(personID: UUID) async throws
}

// MARK: - Debt Use Cases

@MainActor
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

@MainActor
public protocol UpdateDebtUseCase {
    func execute(
        debtID: UUID,
        amount: Decimal,
        kind: CurrencyKind,
        direction: DebtDirection,
        note: String?,
        dueDate: Date?
    ) async throws -> DebtRecord
}

@MainActor
public protocol DeleteDebtUseCase {
    func execute(debtID: UUID) async throws
}

@MainActor
public protocol RecordPaymentUseCase {
    func execute(debtRecordID: UUID, amount: Decimal, note: String?) async throws -> Payment
}

@MainActor
public protocol FetchPaymentsForDebtUseCase {
    func execute(for debtRecordID: UUID) async throws -> [Payment]
}

@MainActor
public protocol FetchDebtsForPersonUseCase {
    func execute(for personID: UUID) async throws -> [DebtRecord]
}

@MainActor
public protocol FetchSingleDebtUseCase {
    func execute(debtID: UUID) async throws -> DebtRecord?
}

@MainActor
public protocol CalculateBalanceUseCase {
    func execute(for personID: UUID) async throws -> Decimal
    func netBalance() async throws -> Decimal
}

// MARK: - Currency Conversion

public protocol CurrencyConverting: Sendable {
    func convertToTRY(amount: Decimal, from currency: CurrencyKind) async throws -> Decimal
    func lastUpdateDate() async -> Date?
}

// MARK: - Analytics

public protocol AnalyticsTracking: Sendable {
    func track(_ event: AnalyticsEvent)
    func setOptOut(_ optOut: Bool)
}
