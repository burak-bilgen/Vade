import Foundation
import Testing
@testable import Core

@Suite("Decimal Helpers")
struct DecimalTests {

    @Test("Rounded scales correctly to 2 decimal places")
    func testRounded() {
        let value: Decimal = 123.45678
        #expect(value.rounded(scale: 2) == 123.46)
    }

    @Test("Rounded scales correctly to 0 decimal places")
    func testRoundedToZero() {
        let value: Decimal = 123.89
        #expect(value.rounded(scale: 0) == 124)
    }

    @Test("isEffectivelyZero returns true for zero")
    func testIsEffectivelyZero() {
        let zero: Decimal = 0
        #expect(zero.isEffectivelyZero == true)
    }

    @Test("isEffectivelyZero returns false for non-zero")
    func testIsNotEffectivelyZero() {
        let nonZero: Decimal = 0.01
        #expect(nonZero.isEffectivelyZero == false)
    }

    @Test("Absolute value of negative number is positive")
    func testAbsoluteValue() {
        let negative: Decimal = -42.5
        #expect(negative.absoluteValue == 42.5)
    }

    @Test("Formatted uses locale-aware formatting")
    func testFormatted() {
        let value: Decimal = 1234.5
        let result = value.formatted(using: Locale(identifier: "tr_TR"))
        #expect(!result.isEmpty)
    }
}
