import Foundation
import Core

// MARK: - Installment Result

public struct InstallmentPlan: Sendable, Hashable {
    public let totalAmount: Decimal
    public let installmentCount: Int
    public let installments: [Decimal]

    public init(totalAmount: Decimal, installmentCount: Int) {
        self.totalAmount = totalAmount
        self.installmentCount = installmentCount
        self.installments = InstallmentCalculator.calculate(
            total: totalAmount,
            count: installmentCount
        )
    }
}

// MARK: - Installment Calculator

/// Calculates equal installment payments with remainder applied to the last installment.
public enum InstallmentCalculator {

    /// Splits `total` into `count` equal installments.
    /// Any remainder from integer division (in kuruş) is added to the last installment.
    public static func calculate(total: Decimal, count: Int) -> [Decimal] {
        guard count > 1 else { return [total] }
        guard total > 0 else { return Array(repeating: .zero, count: count) }

        // Work in kuruş (cents) for exact division
        let totalKurus = total * 100
        let baseKurus = (totalKurus / Decimal(count)).rounded(scale: 0, mode: .down)
        let remainderKurus = totalKurus - (baseKurus * Decimal(count))

        var result: [Decimal] = []
        for i in 0..<count {
            let kurus = baseKurus + (i == count - 1 ? remainderKurus : .zero)
            result.append((kurus / 100).rounded(scale: 2))
        }

        return result
    }

    /// Verifies that the sum of all installments equals the original total.
    public static func verify(_ installments: [Decimal], total: Decimal) -> Bool {
        installments.reduce(.zero, +).rounded(scale: 2) == total.rounded(scale: 2)
    }
}
