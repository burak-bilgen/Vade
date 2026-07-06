import SwiftUI
import SwiftData
import DesignSystem

@main
struct VadeApp: App {
    @State private var modelContainer: ModelContainer?

    var body: some Scene {
        WindowGroup {
            if let container = modelContainer {
                AppCoordinator(modelContainer: container)
                    .start()
                    .modelContainer(container)
            } else {
                ProgressView()
                    .task {
                        modelContainer = createContainer()
                        FontRegistrar.registerFonts()
                    }
            }
        }
    }

    private func createContainer() -> ModelContainer {
        let schema = Schema([
            PersonModel.self,
            DebtRecordModel.self,
            PaymentModel.self,
            AuditEntryModel.self,
        ])

        #if targetEnvironment(simulator)
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        #else
            let config = ModelConfiguration(
                schema: schema,
                cloudKitContainerIdentifier: "iCloud.com.vade"
            )
        #endif

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    Text("Vade App — Preview placeholder")
}
