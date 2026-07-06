import Testing
@testable import DesignSystem

@Suite("Design Tokens")
struct TokensTests {

    @Test("Spacing tokens are positive values")
    func testSpacingTokens() {
        #expect(Spacing.xs > 0)
        #expect(Spacing.s > 0)
        #expect(Spacing.m > 0)
        #expect(Spacing.l > 0)
        #expect(Spacing.xl > 0)
        #expect(Spacing.xxl > 0)
        #expect(Spacing.xxxl > 0)
    }

    @Test("Radius tokens are positive values")
    func testRadiusTokens() {
        #expect(Radius.sm > 0)
        #expect(Radius.md > 0)
        #expect(Radius.lg > 0)
        #expect(Radius.pill > 0)
    }
}
