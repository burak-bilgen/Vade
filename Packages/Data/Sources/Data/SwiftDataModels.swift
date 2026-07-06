import Foundation
import SwiftData

// NOTE: @Relationship inverse keypaths only declared on the "child" side
// to avoid circular @Model macro resolution. SwiftData infers the parent-side
// inverse from the child's explicit declaration.

// MARK: - SwiftData Payment Model (CloudKit-safe)

@Model
public final class PaymentModel {
    public var id: UUID
    public var debtRecordID: UUID
    public var amount: Decimal
    public var date: Date
    public var note: String?

    @Relationship(inverse: \DebtRecordModel._payments)
    public var debtRecord: DebtRecordModel?

    public init(
        id: UUID = UUID(),
        debtRecordID: UUID = UUID(),
        amount: Decimal = .zero,
        date: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.debtRecordID = debtRecordID
        self.amount = amount
        self.date = date
        self.note = note
    }
}

// MARK: - SwiftData DebtRecord Model (CloudKit-safe)

@Model
public final class DebtRecordModel {
    public var id: UUID
    public var personID: UUID
    public var amount: Decimal
    public var kindRawValue: String
    public var directionRawValue: String
    public var note: String?
    public var dueDate: Date?
    public var statusRawValue: String
    public var createdAt: Date
    public var updatedAt: Date

    @Relationship(inverse: \PersonModel._debtRecords)
    public var person: PersonModel?

    @Relationship(deleteRule: .cascade)  // inverse inferred from PaymentModel.debtRecord
    var _payments: [PaymentModel]?

    public var payments: [PaymentModel] {
        _payments ?? []
    }

    public init(
        id: UUID = UUID(),
        personID: UUID = UUID(),
        amount: Decimal = .zero,
        kindRawValue: String = "TRY",
        directionRawValue: String = "receivable",
        note: String? = nil,
        dueDate: Date? = nil,
        statusRawValue: String = "pending",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.personID = personID
        self.amount = amount
        self.kindRawValue = kindRawValue
        self.directionRawValue = directionRawValue
        self.note = note
        self.dueDate = dueDate
        self.statusRawValue = statusRawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - SwiftData Person Model (CloudKit-safe)

@Model
public final class PersonModel {
    public var id: UUID
    public var name: String
    public var phoneNumber: String?
    public var notes: String?
    public var createdAt: Date
    public var isArchived: Bool

    @Relationship(deleteRule: .cascade)  // inverse inferred from DebtRecordModel.person
    var _debtRecords: [DebtRecordModel]?

    public var debtRecords: [DebtRecordModel] {
        _debtRecords ?? []
    }

    public init(
        id: UUID = UUID(),
        name: String = "",
        phoneNumber: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.notes = notes
        self.createdAt = createdAt
        self.isArchived = isArchived
    }
}

// MARK: - SwiftData AuditEntry Model (CloudKit-safe)

@Model
public final class AuditEntryModel {
    public var id: UUID
    public var debtRecordID: UUID
    public var oldValue: String
    public var newValue: String
    public var reasonRawValue: String
    public var timestamp: Date

    public init(
        id: UUID = UUID(),
        debtRecordID: UUID = UUID(),
        oldValue: String = "",
        newValue: String = "",
        reasonRawValue: String = "manualEdit",
        timestamp: Date = Date()
    ) {
        self.id = id
        self.debtRecordID = debtRecordID
        self.oldValue = oldValue
        self.newValue = newValue
        self.reasonRawValue = reasonRawValue
        self.timestamp = timestamp
    }
}
