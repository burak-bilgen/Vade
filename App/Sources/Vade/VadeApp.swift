import SwiftUI
import SwiftData
import DesignSystem
import Data

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
                        do {
                            modelContainer = try ModelContainerFactory.create()
                        } catch {
                            fatalError("Could not create ModelContainer: \(error)")
                        }
                        FontRegistrar.registerFonts()
                    }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    Text(String(localized: "Vade App — Preview placeholder"))
}
