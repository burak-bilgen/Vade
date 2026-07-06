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
    @AppStorage("vade.biometric.enabled") private var isBiometricEnabled = false

    private let biometricAuth = BiometricAuthService()
    private let screenProtector = ScreenProtector()
    private let notificationService = NotificationService()
    private let metricKitService = MetricKitService()
    @State private var diContainer = Container()
    @State private var containerError: String?

    var body: some Scene {
        WindowGroup {
            if let container = modelContainer {
                if isBiometricEnabled && !isAuthenticated && biometricAuth.isBiometryAvailable {
                    lockedView
                } else {
                    AppCoordinator(
                        modelContainer: container,
                        container: diContainer
                    )
                    .start()
                    .modelContainer(container)
                }
            } else {
                ProgressView()
                    .task {
                        assembleContainer()
                        do {
                            modelContainer = try ModelContainerFactory.create()
                        } catch {
                            containerError = error.localizedDescription
                        }
                        FontRegistrar.registerFonts()
                        _ = await notificationService.requestPermission()
                    }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                if isBiometricEnabled {
                    isAuthenticated = false
                }
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
        VStack(spacing: Spacing.xxl) {
            Spacer()
            Image(systemName: "lock.shield")
                .font(Typography.font(for: .hero))
                .foregroundStyle(ColorTokens.accent)
            Text(String(localized: "app.locked.title"))
                .font(Typography.font(for: .title2))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.85)
            Button(String(localized: "app.locked.unlock")) {
                Task {
                    let success = try? await biometricAuth.authenticate(
                        reason: String(localized: "app.locked.biometryReason")
                    )
                    isAuthenticated = success ?? false
                }
            }
            .buttonStyle(.brassPill)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorTokens.background)
    }

    // MARK: - DI Assembly

    private func assembleContainer() {
        diContainer.registerInstance((any BiometricAuthProviding).self, instance: biometricAuth)
        diContainer.registerInstance((any ScreenProtecting).self, instance: screenProtector)
        diContainer.registerInstance((any NotificationScheduling).self, instance: notificationService)
    }
}

// MARK: - Preview

#Preview {
    Text(String(localized: "Vade App — Preview placeholder"))
}
