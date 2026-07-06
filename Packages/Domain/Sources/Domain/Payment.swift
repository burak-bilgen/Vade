import Foundation

public struct Payment: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var debtRecordID: UUID
    public var amount: Decimal
    public var date: Date
    public var note: String?

    public init(
        id: UUID = UUID(),
        debtRecordID: UUID,
        amount: Decimal,
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
