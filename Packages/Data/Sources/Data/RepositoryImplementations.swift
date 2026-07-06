import Foundation
import SwiftData
import Domain
import OSLog

// MARK: - Person Repository

public final class PersonRepository: AddPersonUseCase, FetchPersonsUseCase, @unchecked Sendable {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func execute(name: String, phoneNumber: String?, notes: String?) async throws -> Person {
        let entity = PersonModel(name: name, phoneNumber: phoneNumber, notes: notes)
        modelContext.insert(entity)
        try modelContext.save()
        return entity.toDomain()
    }

    public func execute(includeArchived: Bool = false) async throws -> [Person] {
        let descriptor = FetchDescriptor<PersonModel>(
            predicate: includeArchived ? nil : #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }
}

// MARK: - Debt Repository

public final class DebtRepository: AddDebtUseCase, FetchDebtsForPersonUseCase, @unchecked Sendable {
    private let modelContext: ModelContext
    private let auditTrail: AuditTrailRecording?
    private let logger = Logger(subsystem: "com.vade.data", category: "debt")

    public init(modelContext: ModelContext, auditTrail: AuditTrailRecording? = nil) {
        self.modelContext = modelContext
        self.auditTrail = auditTrail
    }

    public func execute(
        personID: UUID,
        amount: Decimal,
        kind: CurrencyKind,
        direction: DebtDirection,
        note: String?,
        dueDate: Date?
    ) async throws -> DebtRecord {
        let entity = DebtRecordModel(
            personID: personID,
            amount: amount,
            kindRawValue: kind.rawValue,
            directionRawValue: direction.rawValue,
            note: note,
            dueDate: dueDate
        )
        modelContext.insert(entity)
        try modelContext.save()

        await auditTrail?.recordEdit(
            debtRecordID: entity.id,
            oldValue: "",
            newValue: "Debt created: \(amount) \(kind.rawValue)",
            reason: .manualEdit
        )
        logger.info("[DebtRepo] Created debt \(entity.id) for person \(personID)")
        return entity.toDomain()
    }

    public func execute(for personID: UUID) async throws -> [DebtRecord] {
        let descriptor = FetchDescriptor<DebtRecordModel>(
            predicate: #Predicate { $0.personID == personID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }
}

// MARK: - Payment Repository

public final class PaymentRepository: RecordPaymentUseCase, @unchecked Sendable {
    private let modelContext: ModelContext
    private let auditTrail: AuditTrailRecording?
    private let logger = Logger(subsystem: "com.vade.data", category: "payment")

    public init(modelContext: ModelContext, auditTrail: AuditTrailRecording? = nil) {
        self.modelContext = modelContext
        self.auditTrail = auditTrail
    }

    public func execute(debtRecordID: UUID, amount: Decimal, note: String?) async throws -> Payment {
        let payment = PaymentModel(debtRecordID: debtRecordID, amount: amount, note: note)
        modelContext.insert(payment)
        try modelContext.save()

        await auditTrail?.recordEdit(
            debtRecordID: debtRecordID,
            oldValue: "",
            newValue: "Payment recorded: \(amount)",
            reason: .paymentRecorded
        )
        logger.info("[PaymentRepo] Recorded payment \(payment.id) for debt \(debtRecordID)")
        return payment.toDomain()
    }
}

// MARK: - Balance Repository

public final class BalanceRepository: CalculateBalanceUseCase, @unchecked Sendable {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func execute(for personID: UUID) async throws -> Decimal {
        let descriptor = FetchDescriptor<DebtRecordModel>(
            predicate: #Predicate { $0.personID == personID && $0.statusRawValue == "pending" }
        )
        let records = try modelContext.fetch(descriptor)
        return records.reduce(Decimal.zero) { total, record in
            let signed = record.directionRawValue == "receivable" ? record.amount : -record.amount
            return total + signed - record.payments.reduce(Decimal.zero) { $0 + $1.amount }
        }
    }

    public func netBalance() async throws -> Decimal {
        let descriptor = FetchDescriptor<DebtRecordModel>(
            predicate: #Predicate { $0.statusRawValue == "pending" }
        )
        let records = try modelContext.fetch(descriptor)
        return records.reduce(Decimal.zero) { total, record in
            let signed = record.directionRawValue == "receivable" ? record.amount : -record.amount
            return total + signed - record.payments.reduce(Decimal.zero) { $0 + $1.amount }
        }
    }
}

// MARK: - Mappers

public extension PersonModel {
    func toDomain() -> Person {
        Person(id: id, name: name, phoneNumber: phoneNumber, notes: notes,
               createdAt: createdAt, isArchived: isArchived)
    }
}

public extension PaymentModel {
    func toDomain() -> Payment {
        Payment(
            id: id,
            debtRecordID: debtRecordID,
            amount: amount,
            date: date,
            note: note
        )
    }
}

public extension DebtRecordModel {
    func toDomain() -> DebtRecord {
        DebtRecord(
            id: id,
            personID: personID,
            amount: amount,
            kind: CurrencyKind(rawValue: kindRawValue) ?? .tryCoin,
            direction: DebtDirection(rawValue: directionRawValue) ?? .receivable,
            note: note,
            dueDate: dueDate,
            status: DebtStatus(rawValue: statusRawValue) ?? .pending,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
