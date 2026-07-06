import Foundation
import Testing
@testable import FeatureWidget

#if canImport(WidgetKit)
import WidgetKit
#endif

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

    #if canImport(WidgetKit)
    @Test("VadeTimelineProvider can be instantiated")
    func testProviderPlaceholder() {
        let provider = VadeTimelineProvider()
        #expect(provider is VadeTimelineProvider)
    }
    #endif
}
