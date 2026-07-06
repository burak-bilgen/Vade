import SwiftUI
import SwiftData
import FeatureOnboarding
import FeatureDashboard
import FeatureDebtDetail
import FeatureSettings
import DesignSystem
import DIContainer
import Domain
import Observability

@MainActor
final class AppCoordinator: Coordinator {
    weak var parentCoordinator: (any Coordinator)? = nil
    var childCoordinators: [any Coordinator] = []

    private let modelContainer: ModelContainer
    private let diContainer: Container

    init(modelContainer: ModelContainer, container: Container) {
        self.modelContainer = modelContainer
        self.diContainer = container
    }

    func start() -> AnyView {
        AnyView(
            CoordinatorRootView()
        )
    }
}

// MARK: - Coordinator Root View

/// Owns the onboarding state as a proper SwiftUI View.
/// @State MUST live in a View struct — the Coordinator class cannot host it.
public struct CoordinatorRootView: View {
    @State private var onboardingDone = false
    private let analytics: any AnalyticsTracking = AnalyticsService()

    public var body: some View {
        ZStack {
            ColorTokens.background
            if onboardingDone {
                MainTabView()
            } else {
                OnboardingView {
                    onboardingDone = true
                    analytics.track(.onboardingCompleted)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Main Tab View

private struct MainTabView: View {
    var body: some View {
        TabView {
            Tab(String(localized: "tab.dashboard"), systemImage: "house") {
                NavigationStack {
                    DashboardView()
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tint(ColorTokens.accent)
            }
            Tab(String(localized: "tab.people"), systemImage: "person.2") {
                NavigationStack {
                    PeopleListView()
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tint(ColorTokens.accent)
            }
            Tab(String(localized: "tab.settings"), systemImage: "gearshape") {
                NavigationStack {
                    SettingsView()
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tint(ColorTokens.accent)
            }
        }
        .tint(ColorTokens.accent)
    }
}