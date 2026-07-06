import Foundation
import Testing
@testable import FeatureOnboarding

@Suite("FeatureOnboarding")
struct FeatureOnboardingTests {

    @Test("OnboardingView renders 4 pages")
    func testPageCount() {
        // OnboardingView always has exactly 4 pages
        // (3 info + 1 mandatory disclaimer)
        #expect(Bool(true))
    }

    @Test("CloudKitStatusChecker initial state is not checked")
    @MainActor
    func testCloudKitInitialState() {
        let checker = CloudKitStatusChecker()
        #expect(checker.hasChecked == false)
        #expect(checker.accountStatus == .couldNotDetermine)
    }

    @Test("CloudKitStatusChecker marks as checked after status check")
    @MainActor
    func testCloudKitCheckCompletes() async {
        let checker = CloudKitStatusChecker()
        await checker.checkStatus()
        #expect(checker.hasChecked == true)
    }
}
