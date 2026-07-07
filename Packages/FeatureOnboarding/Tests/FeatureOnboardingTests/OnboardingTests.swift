import Foundation
import Testing
@testable import FeatureOnboarding

@Suite("FeatureOnboarding")
struct FeatureOnboardingTests {

    @MainActor
    @Test("OnboardingView renders without crashing")
    func testViewInitializes() {
        let view = OnboardingView(onComplete: {})
        #expect(view is OnboardingView)
    }

    @MainActor
    @Test("OnboardingView accepts completion handler")
    func testCompletionHandler() {
        var didComplete = false
        let view = OnboardingView(onComplete: { didComplete = true })
        #expect(view is OnboardingView)
        view.onComplete()
        #expect(didComplete == true)
    }
}
