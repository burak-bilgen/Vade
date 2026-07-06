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
    @State private var onboardingDone = false
    @State private var analytics: any AnalyticsTracking = AnalyticsService()

    init(modelContainer: ModelContainer, container: Container) {
        self.modelContainer = modelContainer
        self.diContainer = container
    }

    func start() -> AnyView {
        AnyView(
            ZStack {
                if onboardingDone {
                    mainTabView
                } else {
                    OnboardingView {
                        self.onboardingDone = true
                        self.analytics.track(.onboardingCompleted)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
    }

    private var mainTabView: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label(String(localized: "tab.dashboard"), systemImage: "house") }

            NavigationStack { PeopleListView() }
                .tabItem { Label(String(localized: "tab.people"), systemImage: "person.2") }

            NavigationStack { SettingsView() }
                .tabItem { Label(String(localized: "tab.settings"), systemImage: "gearshape") }
        }
        .tint(ColorTokens.accent)
    }
}
