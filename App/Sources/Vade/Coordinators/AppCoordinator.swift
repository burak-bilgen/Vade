import SwiftUI
import SwiftData
import Core
import FeatureOnboarding
import FeatureDashboard
import FeatureDebtDetail
import FeatureSettings
import DesignSystem
import Domain
import Data
import Observability
import Networking

// MARK: - Coordinator Root View

/// Owns the onboarding state as a proper SwiftUI View.
/// @State MUST live in a View struct — the Coordinator class cannot host it.
public struct CoordinatorRootView: View {
    @AppStorage("vade.onboarding.done") private var onboardingDone = false
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.modelContext) private var modelContext

    public var body: some View {
        ZStack {
            ColorTokens.background
            if onboardingDone {
                MainTabView(modelContext: modelContext)
                    .id(languageManager.languageCode)
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            } else {
                OnboardingView {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        onboardingDone = true
                    }
                    AnalyticsService.shared.track(.onboardingCompleted)
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Main Tab View

private struct MainTabView: View {
    let modelContext: ModelContext

    var body: some View {
        let auditTrail = AuditTrailService(modelContainer: modelContext.container)
        let personRepo = PersonRepository(modelContext: modelContext)
        let debtRepo = DebtRepository(modelContext: modelContext, auditTrail: auditTrail)
        let balanceRepo = BalanceRepository(modelContext: modelContext)
        let paymentRepo = PaymentRepository(modelContext: modelContext, auditTrail: auditTrail)
        let rateClient = ExchangeRateClient()

        TabView {
            Tab(String(localized: "tab.dashboard"), systemImage: "house") {
                NavigationStack {
                    DashboardView(
                        personRepo: personRepo,
                        debtRepo: debtRepo,
                        balanceRepo: balanceRepo,
                        paymentRepo: paymentRepo,
                        rateClient: rateClient
                    )
                    .navigationBarTitleDisplayMode(.inline)
                }
                .tint(ColorTokens.accent)
            }
            Tab(String(localized: "tab.people"), systemImage: "person.2") {
                NavigationStack {
                    PeopleListView(
                        personRepo: personRepo,
                        debtRepo: debtRepo,
                        balanceRepo: balanceRepo,
                        paymentRepo: paymentRepo
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(for: Person.self) { person in
                        PersonDetailView(
                            person: person,
                            personRepo: personRepo,
                            debtRepo: debtRepo,
                            balanceRepo: balanceRepo,
                            paymentRepo: paymentRepo
                        )
                    }
                }
                .tint(ColorTokens.accent)
            }
            Tab(String(localized: "tab.settings"), systemImage: "gearshape") {
                NavigationStack {
                    SettingsView(
                        personRepo: personRepo,
                        debtRepo: debtRepo
                    )
                    .navigationBarTitleDisplayMode(.inline)
                }
                .tint(ColorTokens.accent)
            }
        }
        .tint(ColorTokens.accent)
    }
}