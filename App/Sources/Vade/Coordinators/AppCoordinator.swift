import SwiftUI
import SwiftData
import FeatureOnboarding
import FeatureDashboard
import FeatureDebtDetail
import FeatureSettings
import DesignSystem
import DIContainer

@MainActor
final class AppCoordinator: Coordinator {
    weak var parentCoordinator: Coordinator? = nil
    var childCoordinators: [Coordinator] = []

    private let modelContainer: ModelContainer
    private let diContainer: Container
    @State private var onboardingDone = false

    init(modelContainer: ModelContainer, container: Container) {
        self.modelContainer = modelContainer
        self.diContainer = container
    }

    func start() -> AnyView {
        AnyView(
            Group {
                if onboardingDone {
                    mainTabView
                } else {
                    OnboardingView {
                        self.onboardingDone = true
                    }
                }
            }
            .modelContainer(modelContainer)
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
        .tint(Color.vdBrass500)
    }
}
