import SwiftData
import Foundation

/// Creates a CloudKit-synced ModelContainer with the Vade schema.
public enum ModelContainerFactory {
    public static let cloudKitContainerID = "iCloud.com.vade"

    @MainActor
    public static func create() throws -> ModelContainer {
        let schema = Schema([
            PersonModel.self,
            DebtRecordModel.self,
            PaymentModel.self,
            AuditEntryModel.self,
        ])

        #if os(iOS) && !targetEnvironment(simulator)
            let config = ModelConfiguration(
                isStoredInMemoryOnly: false,
                cloudKitContainerIdentifier: cloudKitContainerID
            )
        #else
            // iOS simulators and macOS don't support CloudKit container identifier.
            // CloudKit sync works on real devices only.
            let config = ModelConfiguration(
                isStoredInMemoryOnly: false
            )
        #endif

        return try ModelContainer(for: schema, configurations: [config])
    }
}
