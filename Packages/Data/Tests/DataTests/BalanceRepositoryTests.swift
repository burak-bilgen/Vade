import Foundation
import Testing
import SwiftData
import Domain
@testable import Data

@Suite("BalanceRepository Tests")
struct BalanceRepositoryTests {
    
    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([
            PersonModel.self,
            DebtRecordModel.self,
            PaymentModel.self,
            AuditEntryModel.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
    
    @Test("Calculates balance correctly for single person with single currency")
    @MainActor
    func testSingleCurrencyBalance() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        let personID = UUID()
        let repo = BalanceRepository(modelContext: context)
        
        // Add a receivable debt of 100 TRY
        let debt1 = DebtRecordModel(personID: personID, amount: 100, kindRawValue: "TRY", directionRawValue: "receivable", statusRawValue: "pending")
        context.insert(debt1)
        
        // Add a payable debt of 30 TRY
        let debt2 = DebtRecordModel(personID: personID, amount: 30, kindRawValue: "TRY", directionRawValue: "payable", statusRawValue: "pending")
        context.insert(debt2)
        
        try context.save()
        
        let balance = try await repo.execute(for: personID)
        #expect(balance == 70) // 100 - 30 = 70
    }
    
    @Test("Calculates balance correctly with multi-currency conversion")
    @MainActor
    func testMultiCurrencyBalance() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        let personID = UUID()
        let mockConverter = MockCurrencyConverter(usdRate: 30, eurRate: 35)
        let repo = BalanceRepository(modelContext: context, converter: mockConverter)
        
        // Add a receivable debt of 10 USD
        let debt1 = DebtRecordModel(personID: personID, amount: 10, kindRawValue: "USD", directionRawValue: "receivable", statusRawValue: "pending")
        context.insert(debt1)
        
        // Add a payable debt of 100 TRY
        let debt2 = DebtRecordModel(personID: personID, amount: 100, kindRawValue: "TRY", directionRawValue: "payable", statusRawValue: "pending")
        context.insert(debt2)
        
        try context.save()
        
        let balance = try await repo.execute(for: personID)
        // 10 USD * 30 TRY/USD = 300 TRY (receivable)
        // 100 TRY (payable)
        // 300 - 100 = 200 TRY
        #expect(balance == 200)
    }
    
    @Test("Calculates net bakiye correctly with active payments")
    @MainActor
    func testBalanceWithPayments() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        let personID = UUID()
        let mockConverter = MockCurrencyConverter(usdRate: 30, eurRate: 35)
        let repo = BalanceRepository(modelContext: context, converter: mockConverter)
        
        // Add a receivable debt of 10 USD
        let debt1 = DebtRecordModel(personID: personID, amount: 10, kindRawValue: "USD", directionRawValue: "receivable", statusRawValue: "pending")
        context.insert(debt1)
        
        // Add a payment of 4 USD to the USD debt
        let payment = PaymentModel(debtRecordID: debt1.id, amount: 4, note: "Partial payment")
        payment.debtRecord = debt1
        context.insert(payment)
        
        try context.save()
        
        let balance = try await repo.execute(for: personID)
        // (10 - 4) USD * 30 TRY/USD = 180 TRY
        #expect(balance == 180)
    }
    
    @Test("Net balance computes total correctly across all pending records")
    @MainActor
    func testNetBalanceGlobal() async throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        let mockConverter = MockCurrencyConverter(usdRate: 30, eurRate: 35)
        let repo = BalanceRepository(modelContext: context, converter: mockConverter)
        
        let person1 = UUID()
        let person2 = UUID()
        
        // Person 1: 5 USD receivable
        let debt1 = DebtRecordModel(personID: person1, amount: 5, kindRawValue: "USD", directionRawValue: "receivable", statusRawValue: "pending")
        context.insert(debt1)
        
        // Person 2: 10 EUR payable
        let debt2 = DebtRecordModel(personID: person2, amount: 10, kindRawValue: "EUR", directionRawValue: "payable", statusRawValue: "pending")
        context.insert(debt2)
        
        try context.save()
        
        let globalNet = try await repo.netBalance()
        // 5 USD * 30 = +150
        // 10 EUR * 35 = -350
        // Net = 150 - 350 = -200
        #expect(globalNet == -200)
    }
}

// MARK: - Mock Currency Converter

private struct MockCurrencyConverter: CurrencyConverting, Sendable {
    let usdRate: Decimal
    let eurRate: Decimal
    
    init(usdRate: Decimal = 30, eurRate: Decimal = 35) {
        self.usdRate = usdRate
        self.eurRate = eurRate
    }
    
    func convertToTRY(amount: Decimal, from currency: CurrencyKind) async throws -> Decimal {
        switch currency {
        case .tryCoin:
            return amount
        case .usd:
            return amount * usdRate
        case .eur:
            return amount * eurRate
        case .goldGram, .goldQuarter, .goldHalf, .goldFull, .goldRepublic:
            return amount * currency.gramEquivalent * 2400
        }
    }
    
    func lastUpdateDate() async -> Date? {
        nil
    }
}
