import SwiftUI
import SwiftData

/// Root coordinator that owns the entire navigation graph.
/// This is the composition root — the ONLY place where the DI container is assembled.
@MainActor
final class AppCoordinator: Coordinator {
    weak var parentCoordinator: Coordinator? = nil
    var childCoordinators: [Coordinator] = []

    private let modelContainer: ModelContainer
    private var hasCompletedOnboarding = false

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func start() -> AnyView {
        AnyView(
            Group {
                if hasCompletedOnboarding {
                    placeholderDashboardView
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

    // MARK: - Placeholder Dashboard

    private var placeholderDashboardView: some View {
        TabView {
            Text(String(localized: "tab.dashboard"))
                .tabItem {
                    Label(String(localized: "tab.dashboard"), systemImage: "house")
                }
            Text(String(localized: "tab.people"))
                .tabItem {
                    Label(String(localized: "tab.people"), systemImage: "person.2")
                }
            Text(String(localized: "tab.settings"))
                .tabItem {
                    Label(String(localized: "tab.settings"), systemImage: "gearshape")
                }
        }
        .tint(Color("brass500", bundle: .main))
    }
}
