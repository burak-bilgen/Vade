import Foundation
import SwiftData
import Domain
import OSLog

// MARK: - Audit Trail Protocol

public protocol AuditTrailRecording: Sendable {
    func recordEdit(debtRecordID: UUID, oldValue: String, newValue: String, reason: AuditReason) async
    func recordSyncConflict(debtRecordID: UUID, localValue: String, remoteValue: String) async
}

// MARK: - Audit Trail Service

/// Append-only audit trail - every mutation and CloudKit conflict is recorded.
/// Entries are never modified or deleted.
public final class AuditTrailService: AuditTrailRecording {
    private let modelContainer: ModelContainer
    private let logger = Logger(subsystem: "com.vade.data", category: "audit")

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
        do {
            try context.save()
        } catch {
            logger.error("[AuditTrail] Failed to save edit record for debt \(debtRecordID): \(error.localizedDescription)")
        }
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
        do {
            try context.save()
        } catch {
            logger.error("[AuditTrail] Failed to save sync conflict for debt \(debtRecordID): \(error.localizedDescription)")
        }
    }
}
