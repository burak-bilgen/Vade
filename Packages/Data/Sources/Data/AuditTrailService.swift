import Foundation
import SwiftData
import Domain

// MARK: - Audit Trail Protocol

public protocol AuditTrailRecording: Sendable {
    func recordEdit(debtRecordID: UUID, oldValue: String, newValue: String, reason: AuditReason) async
    func recordSyncConflict(debtRecordID: UUID, localValue: String, remoteValue: String) async
}

// MARK: - Audit Trail Service

/// Append-only audit trail — every mutation and CloudKit conflict is recorded.
/// Entries are never modified or deleted.
public final class AuditTrailService: AuditTrailRecording, @unchecked Sendable {
    private let modelContainer: ModelContainer

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    public func recordEdit(
        debtRecordID: UUID,
        oldValue: String,
        newValue: String,
        reason: AuditReason
    ) async {
        let context = ModelContext(modelContainer)
        let entry = AuditEntryModel(
            debtRecordID: debtRecordID,
            oldValue: oldValue,
            newValue: newValue,
            reasonRawValue: reason.rawValue
        )
        context.insert(entry)
        try? context.save()
    }

    public func recordSyncConflict(
        debtRecordID: UUID,
        localValue: String,
        remoteValue: String
    ) async {
        let context = ModelContext(modelContainer)
        let entry = AuditEntryModel(
            debtRecordID: debtRecordID,
            oldValue: localValue,
            newValue: remoteValue,
            reasonRawValue: AuditReason.cloudKitConflict.rawValue
        )
        context.insert(entry)
        try? context.save()
    }
}
