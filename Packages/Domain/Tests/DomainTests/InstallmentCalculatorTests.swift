import Foundation
import Testing
import Domain

@Suite("Installment Calculator")
struct InstallmentCalculatorTests {

    @Test("Single installment returns total",
          arguments: [
            (total: Decimal(1000), count: 1),
            (total: Decimal(500.50), count: 1),
          ])
    func testSingleInstallment(total: Decimal, count: Int) {
        let plan = InstallmentPlan(totalAmount: total, installmentCount: count)
        #expect(plan.installments.count == 1)
        #expect(plan.installments[0] == total)
    }

    @Test("Equal installments sum to total",
          arguments: [
            (total: Decimal(3000), count: 3),
            (total: Decimal(1000), count: 4),
            (total: Decimal(5000), count: 6),
          ])
    func testSumEqualsTotal(total: Decimal, count: Int) {
        let plan = InstallmentPlan(totalAmount: total, installmentCount: count)
        #expect(plan.installments.count == count)
        let sum = plan.installments.reduce(Decimal.zero, +)
        #expect(sum.rounded(scale: 2) == total.rounded(scale: 2))
    }

    @Test("Remainder kuruş appended to last installment",
          arguments: [
            (total: Decimal(1000), count: 3),
            // 1000 / 3 = 333.33 * 3 = 999.99, remainder 0.01 on last → 333.34
            (total: Decimal(100), count: 3),
            // 100 / 3 = 33.33 * 3 = 99.99, remainder 0.01 on last → 33.34
            (total: Decimal(500), count: 7),
          ])
    func testRemainderDistribution(total: Decimal, count: Int) {
        let plan = InstallmentPlan(totalAmount: total, installmentCount: count)

        // Last installment should be >= base installments
        let baseAmount = plan.installments[0]
        let lastAmount = plan.installments[count - 1]
        #expect(lastAmount >= baseAmount)

        // Verify total matches
        let sum = plan.installments.reduce(Decimal.zero, +)
        #expect(sum.rounded(scale: 2) == total.rounded(scale: 2))
    }

    @Test("Zero amount produces zero installments")
    func testZeroAmount() {
        let plan = InstallmentPlan(totalAmount: .zero, installmentCount: 5)
        #expect(plan.installments.allSatisfy { $0 == .zero })
    }

    @Test("Verification confirms correct plans")
    func testVerification() {
        let installments = InstallmentCalculator.calculate(total: 1000, count: 3)
        #expect(InstallmentCalculator.verify(installments, total: 1000))
    }
}
