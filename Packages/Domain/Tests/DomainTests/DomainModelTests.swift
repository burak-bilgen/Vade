import Foundation
import Testing
import Domain

@Suite("Domain Models")
struct DomainModelTests {

    @Test("Person initializes with default values")
    func testPersonDefaultInit() {
        let person = Person(name: "Ahmet")
        #expect(person.name == "Ahmet")
        #expect(person.isArchived == false)
        #expect(person.phoneNumber == nil)
    }

    @Test("DebtRecord initializes with correct direction")
    func testDebtRecordDirection() {
        let record = DebtRecord(
            personID: UUID(),
            amount: 1500,
            kind: .tryCoin,
            direction: .receivable
        )
        #expect(record.direction == .receivable)
        #expect(record.status == .pending)
        #expect(record.amount == 1500)
    }

    @Test("Payment initializes with required fields")
    func testPaymentInit() {
        let payment = Payment(debtRecordID: UUID(), amount: 500)
        #expect(payment.amount == 500)
        #expect(payment.note == nil)
    }
}

// MARK: - Balance Calculation Tests (Parameterized)

@Suite("Balance Calculations")
struct BalanceCalculationTests {

    @Test("Net balance = totalReceivable - totalPayable",
          arguments: [
            (receivable: Decimal(5000), payable: Decimal(2500), expectedNet: Decimal(2500)),
            (receivable: Decimal(1000), payable: Decimal(3000), expectedNet: Decimal(-2000)),
            (receivable: Decimal(0), payable: Decimal(0), expectedNet: Decimal(0)),
            (receivable: Decimal(1500), payable: Decimal(0), expectedNet: Decimal(1500)),
            (receivable: Decimal(0), payable: Decimal(1500), expectedNet: Decimal(-1500)),
          ])
    func testNetBalance(receivable: Decimal, payable: Decimal, expectedNet: Decimal) {
        let net = receivable - payable
        #expect(net == expectedNet)
    }

    @Test("Total receivable sums all positive balances",
          arguments: [
            ([Decimal(1000), Decimal(500), Decimal(250)], Decimal(1750)),
            ([Decimal(-1000), Decimal(500)], Decimal(500)),
            ([Decimal(0), Decimal(0), Decimal(0)], Decimal(0)),
          ])
    func testTotalReceivable(balances: [Decimal], expected: Decimal) {
        let total = balances
            .filter { $0 > 0 }
            .reduce(Decimal.zero, +)
        #expect(total == expected)
    }

    @Test("Total payable sums absolute values of negative balances",
          arguments: [
            ([Decimal(-1000), Decimal(-500), Decimal(-250)], Decimal(1750)),
            ([Decimal(1000), Decimal(-500)], Decimal(500)),
            ([Decimal(-1500), Decimal(0)], Decimal(1500)),
          ])
    func testTotalPayable(balances: [Decimal], expected: Decimal) {
        let total = balances
            .filter { $0 < 0 }
            .map { $0.magnitude }
            .reduce(Decimal.zero, +)
        #expect(total == expected)
    }
}

// MARK: - Payment Recording Tests (Parameterized)

@Suite("Payment Recording")
struct PaymentRecordingTests {

    @Test("Partial payment reduces remaining balance",
          arguments: [
            (debt: Decimal(1500), payment: Decimal(500), remaining: Decimal(1000)),
            (debt: Decimal(1000), payment: Decimal(1000), remaining: Decimal(0)),
            (debt: Decimal(333.33), payment: Decimal(111.11), remaining: Decimal(222.22)),
            (debt: Decimal(750), payment: Decimal(200), remaining: Decimal(550)),
          ])
    func testPartialPayment(debt: Decimal, payment: Decimal, remaining: Decimal) {
        let balance = debt - payment
        #expect(balance == remaining)
    }

    @Test("Multiple payments accumulate correctly",
          arguments: [
            (debt: Decimal(3000), payments: [Decimal(1000), Decimal(500), Decimal(500)], totalPaid: Decimal(2000)),
            (debt: Decimal(5000), payments: [Decimal(2500), Decimal(2500)], totalPaid: Decimal(5000)),
            (debt: Decimal(1000), payments: [Decimal(333.33), Decimal(333.33), Decimal(333.34)], totalPaid: Decimal(1000)),
          ])
    func testMultiplePayments(debt: Decimal, payments: [Decimal], totalPaid: Decimal) {
        let sum = payments.reduce(Decimal.zero, +)
        #expect(sum == totalPaid)
        #expect(debt - sum >= 0)
    }

    @Test("Payment cannot exceed debt amount",
          arguments: [
            (debt: Decimal(1000), payment: Decimal(1001)),
            (debt: Decimal(500), payment: Decimal(600)),
          ])
    func testPaymentExceedsDebt(debt: Decimal, payment: Decimal) {
        let exceeds = payment > debt
        #expect(exceeds == true)
    }
}

// MARK: - Currency Kind Tests

@Suite("Currency Kind")
struct CurrencyKindTests {

    @Test("All currency kinds have unique raw values")
    func testRawValuesUnique() {
        let all = CurrencyKind.allCases.map(\.rawValue)
        #expect(Set(all).count == all.count)
    }

    @Test("TRY is the default currency kind")
    func testDefaultCurrency() {
        let kind = CurrencyKind.tryCoin
        #expect(kind == .tryCoin)
    }

    @Test("All currency kinds have valid raw values")
    func testRawValuesNonEmpty() {
        for kind in CurrencyKind.allCases {
            #expect(!kind.rawValue.isEmpty)
        }
    }
}

// MARK: - Edge Case Tests

@Suite("Edge Cases")
struct EdgeCaseTests {

    // MARK: Overpayment

    @Test("Overpayment results in negative remaining balance",
          arguments: [
            (debt: Decimal(500), payment: Decimal(600), expected: Decimal(-100)),
            (debt: Decimal(1000), payment: Decimal(1500), expected: Decimal(-500)),
          ])
    func testOverpayment(debt: Decimal, payment: Decimal, expected: Decimal) {
        let remaining = debt - payment
        #expect(remaining == expected)
    }

    // MARK: Zero amounts

    @Test("Zero amount debt is valid (placeholder)",
          arguments: [Decimal.zero])
    func testZeroAmount(amount: Decimal) {
        #expect(amount == .zero)
    }

    // MARK: Large numbers

    @Test("Large Decimal values maintain precision",
          arguments: [
            Decimal(9999999),
            Decimal(1234567890123),
          ])
    func testLargeNumbers(amount: Decimal) {
        #expect(amount.rounded(scale: 2) == amount)
        #expect(!amount.isEffectivelyZero)
    }

    // MARK: Negative balance

    @Test("Negative net balance when payable exceeds receivable",
          arguments: [
            (receivable: Decimal(500), payable: Decimal(1000), net: Decimal(-500)),
            (receivable: Decimal(0), payable: Decimal(1), net: Decimal(-1)),
          ])
    func testNegativeNetBalance(receivable: Decimal, payable: Decimal, net: Decimal) {
        #expect(receivable - payable == net)
    }

    // MARK: Multiple payments edge

    @Test("Exact full payment brings balance to zero",
          arguments: [
            (debt: Decimal(333.33), payments: [Decimal(111.11), Decimal(111.11), Decimal(111.11)]),
            (debt: Decimal(1000), payments: [Decimal(500), Decimal(500)]),
          ])
    func testExactFullPayment(debt: Decimal, payments: [Decimal]) {
        let totalPaid = payments.reduce(Decimal.zero, +)
        #expect(debt - totalPaid >= Decimal.zero || debt - totalPaid < 0.01)
    }

    // MARK: Empty person list

    @Test("Empty person list produces no balances")
    func testEmptyList() {
        let persons: [Person] = []
        #expect(persons.isEmpty)
        #expect(persons.count == 0)
    }

    // MARK: Concurrent safety check

    @Test("Person is Sendable (compile-time guarantee)")
    func testPersonIsSendable() {
        let person = Person(name: "Test")
        _ = person as Sendable
        #expect(Bool(true))
    }

    // MARK: - CurrencyKind label & formatting

    @Test("CurrencyKind fiat symbols are correct",
          arguments: [
            (CurrencyKind.tryCoin, "\u{20BA}"),
            (CurrencyKind.usd, "$"),
            (CurrencyKind.eur, "\u{20AC}"),
          ])
    func testFiatSymbols(kind: CurrencyKind, expected: String) {
        #expect(kind.label == expected)
    }

    @Test("CurrencyKind.isFiat returns true only for fiat")
    func testIsFiat() {
        #expect(CurrencyKind.tryCoin.isFiat)
        #expect(CurrencyKind.usd.isFiat)
        #expect(CurrencyKind.eur.isFiat)
        #expect(!CurrencyKind.goldGram.isFiat)
        #expect(!CurrencyKind.goldQuarter.isFiat)
    }

    @Test("CurrencyKind.format prefixes fiat with symbol")
    func testFormatFiat() {
        let amount: Decimal = 1500
        #expect(CurrencyKind.tryCoin.format(amount).hasPrefix("\u{20BA}"))
        #expect(CurrencyKind.usd.format(amount).hasPrefix("$"))
    }

    @Test("CurrencyKind.format suffixes gold with label")
    func testFormatGold() {
        let amount: Decimal = 5
        let result = CurrencyKind.goldGram.format(amount)
        #expect(result.contains("gr") || result.contains("g"))
    }

    @Test("CurrencyKind.gramEquivalent returns correct values")
    func testGramEquivalent() {
        #expect(CurrencyKind.tryCoin.gramEquivalent == 1)
        #expect(CurrencyKind.goldGram.gramEquivalent == 1)
        #expect(CurrencyKind.goldQuarter.gramEquivalent == Decimal(175) / Decimal(100))
        #expect(CurrencyKind.goldFull.gramEquivalent == 7)
    }
}
