import Foundation
import Testing
@testable import FeatureWidget

@Suite("FeatureWidget")
struct FeatureWidgetTests {

    @Test("VadeWidgetEntry initializes with default values")
    func testDefaultEntry() {
        let entry = VadeWidgetEntry()
        #expect(entry.netBalance == .zero)
        #expect(entry.totalReceivable == .zero)
        #expect(entry.totalPayable == .zero)
        #expect(entry.personCount == 0)
    }

    @Test("VadeWidgetEntry stores custom values correctly")
    func testCustomEntry() {
        let entry = VadeWidgetEntry(
            netBalance: 3500,
            totalReceivable: 5000,
            totalPayable: 1500,
            personCount: 4
        )
        #expect(entry.netBalance == 3500)
        #expect(entry.personCount == 4)
    }

    @Test("VadeWidgetProvider returns non-nil placeholder")
    func testProviderPlaceholder() {
        let placeholder = VadeWidgetProvider.placeholder()
        #expect(placeholder.personCount == 3)
        #expect(placeholder.netBalance == 2500)
    }
}
