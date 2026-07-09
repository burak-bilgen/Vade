import SwiftUI
import SwiftData
import DesignSystem
import Data
import Core
import Domain
import Observability

// MARK: - iOS Only Guard
// Vade is an iOS-only application. This prevents accidental compilation on macOS.
#if os(macOS)
#error("Vade is iOS-only - macOS and Mac Catalyst are not supported.")
#endif

@main
struct VadeApp: App {
    @State private var modelContainer: ModelContainer?
    @State private var isAuthenticated = false
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(UserDefaultsKeys.biometricEnabled) private var isBiometricEnabled = false
    @State private var languageManager = LanguageManager.shared

    private let biometricAuth = BiometricAuthService()
    private let screenProtector = ScreenProtector()
    private let notificationService = NotificationService(
        onPermissionRequested: { granted in
            AnalyticsService.shared.track(.notificationPermission(granted: granted))
        },
        onScheduled: {
            AnalyticsService.shared.track(.notificationScheduled)
        }
    )
    private let metricKitService = MetricKitService()
    @State private var containerError: String?
    @State private var analytics: any AnalyticsTracking = AnalyticsService.shared
    @State private var hasTrackedAppOpen = false

    init() {
        AppFont.register()
    }

    var body: some Scene {
        WindowGroup {
            if let error = containerError {
                ZStack {
                    ColorTokens.background.ignoresSafeArea()
                    VStack(spacing: Spacing.l) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(Font.system(size: 56, weight: .bold))
                            .foregroundStyle(ColorTokens.negative)
                        Text("app.error.containerFailed")
                            .font(Typography.font(for: .headline))
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text(error)
                            .font(Typography.font(for: .caption))
                            .foregroundStyle(ColorTokens.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Spacing.xl)
                }
            } else if let container = modelContainer {
                if isBiometricEnabled && !isAuthenticated && biometricAuth.isBiometryAvailable {
                    lockedView
                } else {
                    CoordinatorRootView()
                        .modelContainer(container)
                        .environment(languageManager)
                        .environment(\.locale, languageManager.locale)
                        .preferredColorScheme(.light)
                }
            } else {
                ZStack {
                    ColorTokens.background.ignoresSafeArea()
                    VStack(spacing: Spacing.l) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("app.loading")
                            .font(Typography.font(for: .caption))
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                }
                .task {
                        do {
                            modelContainer = try ModelContainerFactory.create()
                        } catch {
                            containerError = error.localizedDescription
                        }
                        _ = await notificationService.requestPermission()
                    }
            }
        }
        .onChange(of: languageManager.languageCode) { _, newCode in
            analytics.track(.languageChanged(to: newCode))
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
                if !hasTrackedAppOpen {
                    hasTrackedAppOpen = true
                    analytics.track(.appOpened)
                }
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
                .font(Font.system(size: 56, weight: .bold))
                .foregroundStyle(ColorTokens.accent)
            Text("app.locked.title")
                .font(Typography.font(for: .title2))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.85)
            Button("app.locked.unlock") {
                Task {
                    let success = try? await biometricAuth.authenticate(
                        reason: String(localized: "app.locked.biometryReason", locale: languageManager.locale)
                    )
                    isAuthenticated = success ?? false
                }
            }
            .buttonStyle(.primaryPill)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorTokens.background)
    }

}

// MARK: - Preview

#Preview {
    Text("app.preview.placeholder")
}
