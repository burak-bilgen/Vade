import SwiftUI
import SwiftData
import FeatureOnboarding
import FeatureDashboard
import FeatureDebtDetail
import FeatureSettings
import DesignSystem
import DIContainer

/// Root coordinator that owns the entire navigation graph.
/// This is the composition root — the ONLY place where the DI container is assembled.
@MainActor
final class AppCoordinator: Coordinator {
    weak var parentCoordinator: Coordinator? = nil
    var childCoordinators: [Coordinator] = []

    private let modelContainer: ModelContainer
    private let diContainer: Container
    private var hasCompletedOnboarding = false

    init(modelContainer: ModelContainer, container: Container) {
        self.modelContainer = modelContainer
        self.diContainer = container
    }

    func start() -> AnyView {
        AnyView(
            Group {
                if hasCompletedOnboarding {
                    mainTabView
                } else {
                    onboardingView
                }
            }
        )
    }

    // MARK: - Onboarding

    private var onboardingView: some View {
        OnboardingView(
            onComplete: { [weak self] in
                self?.hasCompletedOnboarding = true
            }
        )
    }

    // MARK: - Main Tab View

    private var mainTabView: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label(
                    String(localized: "tab.dashboard"),
                    systemImage: "house"
                )
            }

            NavigationStack {
                PeopleListView()
            }
            .tabItem {
                Label(
                    String(localized: "tab.people"),
                    systemImage: "person.2"
                )
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(
                    String(localized: "tab.settings"),
                    systemImage: "gearshape"
                )
            }
        }
        .tint(Color("brass500", bundle: .main))
        .modelContainer(modelContainer)
    }
}
