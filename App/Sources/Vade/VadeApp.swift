import SwiftUI
import SwiftData
import DesignSystem
import Data
import Core
import DIContainer

@main
struct VadeApp: App {
    @State private var modelContainer: ModelContainer?
    @State private var isAuthenticated = false
    @Environment(\.scenePhase) private var scenePhase

    private let biometricAuth = BiometricAuthService()
    private let screenProtector = ScreenProtector()
    private let notificationService = NotificationService()
    @State private var diContainer = Container()

    var body: some Scene {
        WindowGroup {
            if let container = modelContainer {
                if isAuthenticated || !biometricAuth.isBiometryAvailable {
                    AppCoordinator(
                        modelContainer: container,
                        container: diContainer
                    )
                    .start()
                    .modelContainer(container)
                } else {
                    lockedView
                }
            } else {
                ProgressView()
                    .task {
                        assembleContainer()
                        do {
                            modelContainer = try ModelContainerFactory.create()
                        } catch {
                            fatalError("Could not create ModelContainer: \(error)")
                        }
                        FontRegistrar.registerFonts()
                        _ = await notificationService.requestPermission()
                    }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                screenProtector.enableBlurOnBackground()
            case .active:
                screenProtector.disableBlurOnBackground()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }

    // MARK: - Locked View

    private var lockedView: some View {
        VStack(spacing: 32) {
            Image(systemName: "lock.shield")
                .font(.system(size: 56))
                .foregroundColor(Color("brass500"))
            Text(String(localized: "app.locked.title"))
                .font(.title2)
            Button(String(localized: "app.locked.unlock")) {
                Task {
                    let success = try? await biometricAuth.authenticate(
                        reason: String(localized: "app.locked.biometryReason")
                    )
                    isAuthenticated = success ?? false
                }
            }
            .buttonStyle(.brassPill)
        }
        .padding(48)
    }

    // MARK: - DI Assembly

    private func assembleContainer() {
        // Core services
        diContainer.registerInstance(BiometricAuthProviding.self, instance: biometricAuth)
        diContainer.registerInstance(ScreenProtecting.self, instance: screenProtector)
        diContainer.registerInstance(NotificationScheduling.self, instance: notificationService)

        // Observability
        _ = MetricKitService()
        _ = CloudKitSyncObserver()
    }
}

// MARK: - Preview

#Preview {
    Text(String(localized: "Vade App — Preview placeholder"))
}
