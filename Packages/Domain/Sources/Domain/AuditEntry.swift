import Foundation

public struct AuditEntry: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var debtRecordID: UUID
    public var oldValue: String
    public var newValue: String
    public var reason: AuditReason
    public var timestamp: Date

    public init(
        id: UUID = UUID(),
        debtRecordID: UUID,
        oldValue: String,
        newValue: String,
        reason: AuditReason,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.debtRecordID = debtRecordID
        self.oldValue = oldValue
        self.newValue = newValue
        self.reason = reason
        self.timestamp = timestamp
    }
}

public enum AuditReason: String, Codable, Sendable {
    case manualEdit
    case cloudKitConflict
    case paymentRecorded
    case deleted
}
