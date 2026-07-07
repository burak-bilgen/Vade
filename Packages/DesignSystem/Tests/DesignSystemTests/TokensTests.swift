import Testing
@testable import DesignSystem

@Suite("Design Tokens")
struct TokensTests {

    @Test("Spacing tokens follow 4pt base grid")
    func testSpacingTokens() {
        #expect(Spacing.xxs == 4)
        #expect(Spacing.s == 8)
        #expect(Spacing.m == 12)
        #expect(Spacing.l == 16)
        #expect(Spacing.xl == 20)
        #expect(Spacing.xxl == 24)
        #expect(Spacing.xxxl == 32)
        #expect(Spacing.huge == 40)
        #expect(Spacing.massive == 48)
    }

    @Test("Radius tokens are ordered correctly")
    func testRadiusTokens() {
        #expect(Radius.xs < Radius.sm)
        #expect(Radius.sm < Radius.md)
        #expect(Radius.md < Radius.lg)
        #expect(Radius.lg < Radius.xl)
        #expect(Radius.xl < Radius.pill)
        #expect(Radius.pill == 999)
    }

    @Test("Elevation shadow styles are ordered by intensity")
    func testElevationOrdering() {
        let levels = [
            Elevation.level0,
            Elevation.level1,
            Elevation.level2,
            Elevation.level3,
            Elevation.level4,
        ]
        for i in 1..<levels.count {
            #expect(levels[i].radius > levels[i - 1].radius ||
                    levels[i].y > levels[i - 1].y)
        }
    }

    @Test("Color tokens are accessible as Colors")
    func testColorTokensExist() {
        // Verify the tokens compile and resolve to Color values
        _ = ColorTokens.background
        _ = ColorTokens.surface
        _ = ColorTokens.surfaceElevated
        _ = ColorTokens.border
        _ = ColorTokens.borderSubtle
        _ = ColorTokens.textPrimary
        _ = ColorTokens.textSecondary
        _ = ColorTokens.textTertiary
        _ = ColorTokens.accent
        _ = ColorTokens.accentLight
        _ = ColorTokens.accentDark
        _ = ColorTokens.positive
        _ = ColorTokens.positiveLight
        _ = ColorTokens.negative
        _ = ColorTokens.negativeLight
        _ = ColorTokens.chartBlue
        _ = ColorTokens.chartPurple
        _ = ColorTokens.chartOrange
        _ = ColorTokens.chartTeal
    }

    @Test("Typography font roles return valid fonts")
    func testTypographyRoles() {
        let roles: [Typography.FontRole] = [
            .display, .displayMedium, .title, .title2,
            .headline, .body, .bodyEmphasis,
            .amount, .amountSmall,
            .caption, .label,
            .button, .buttonSmall, .tab,
        ]
        for role in roles {
            let font = Typography.font(for: role)
            #expect(font != Font.system(size: 12)) // ensures we got a custom font
        }
    }
}
