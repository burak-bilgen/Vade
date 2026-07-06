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
            Text("Dashboard")
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }
            Text("Kişiler")
                .tabItem {
                    Label("Kişiler", systemImage: "person.2")
                }
            Text("Ayarlar")
                .tabItem {
                    Label("Ayarlar", systemImage: "gearshape")
                }
        }
        .tint(Color("brass500", bundle: .main))
    }
}
