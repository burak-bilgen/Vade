import Foundation
import Testing
import SwiftData
@testable import FeatureDashboard
@testable import Data
@testable import Networking

// MARK: - Mock Rate Provider

private actor MockRateProvider: ExchangeRateProviding {
    func fetchRate(for currency: String) async throws -> Decimal? { nil }
    func fetchGoldRatePerGram() async throws -> Decimal? { nil }
    func fetchAllRates() async throws -> [(code: String, rate: Decimal)] { [] }
    func lastUpdateDate() async -> Date? { nil }
}

@Suite("DashboardViewModel")
struct DashboardViewModelTests {

    @MainActor
    @Test("ViewModel initializes with zero balances on empty store")
    func testInitialState() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PersonModel.self, DebtRecordModel.self, PaymentModel.self,
            configurations: config
        )
        let personRepo = PersonRepository(modelContext: container.mainContext)
        let debtRepo = DebtRepository(modelContext: container.mainContext)
        let balanceRepo = BalanceRepository(modelContext: container.mainContext)
        let vm = DashboardViewModel(
            personRepo: personRepo,
            debtRepo: debtRepo,
            balanceRepo: balanceRepo,
            rateClient: MockRateProvider()
        )
        await vm.loadData()

        #expect(vm.persons.isEmpty)
        #expect(vm.totalReceivable == .zero)
        #expect(vm.totalPayable == .zero)
        #expect(vm.netBalance == .zero)
        #expect(vm.upcomingItems.isEmpty)
    }

    @MainActor
    @Test("Total receivable and payable are correctly computed")
    func testBalancesComputed() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PersonModel.self, DebtRecordModel.self, PaymentModel.self,
            configurations: config
        )
        let context = container.mainContext

        let person1 = PersonModel(name: "Person 1")
        let person2 = PersonModel(name: "Person 2")
        context.insert(person1)
        context.insert(person2)
        try context.save()

        let receivable = DebtRecordModel(personID: person1.id, amount: 1000,
                                          kindRawValue: "TRY", directionRawValue: "receivable")
        let payable = DebtRecordModel(personID: person2.id, amount: 500,
                                       kindRawValue: "TRY", directionRawValue: "payable")
        context.insert(receivable)
        context.insert(payable)
        try context.save()

        let personRepo = PersonRepository(modelContext: context)
        let debtRepo = DebtRepository(modelContext: context)
        let balanceRepo = BalanceRepository(modelContext: context)
        let vm = DashboardViewModel(
            personRepo: personRepo,
            debtRepo: debtRepo,
            balanceRepo: balanceRepo,
            rateClient: MockRateProvider()
        )
        await vm.loadData()

        #expect(vm.totalReceivable == 1000)
        #expect(vm.totalPayable == 500)
        #expect(vm.netBalance == 500)
    }

    @MainActor
    @Test("Upcoming items include debts with due dates")
    func testUpcomingItems() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PersonModel.self, DebtRecordModel.self, PaymentModel.self,
            configurations: config
        )
        let context = container.mainContext

        let person = PersonModel(name: "Ahmet")
        context.insert(person)
        try context.save()

        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let debtWithDue = DebtRecordModel(personID: person.id, amount: 2000,
                                           kindRawValue: "TRY", directionRawValue: "receivable",
                                           dueDate: futureDate)
        let debtNoDue = DebtRecordModel(personID: person.id, amount: 500,
                                         kindRawValue: "TRY", directionRawValue: "payable",
                                         dueDate: nil)
        context.insert(debtWithDue)
        context.insert(debtNoDue)
        try context.save()

        let personRepo = PersonRepository(modelContext: context)
        let debtRepo = DebtRepository(modelContext: context)
        let balanceRepo = BalanceRepository(modelContext: context)
        let vm = DashboardViewModel(
            personRepo: personRepo,
            debtRepo: debtRepo,
            balanceRepo: balanceRepo,
            rateClient: MockRateProvider()
        )
        await vm.loadData()

        #expect(vm.upcomingItems.count == 1)
        #expect(vm.upcomingItems.first?.amount == 2000)
    }

    @MainActor
    @Test("Recent activity contains debt records sorted by date")
    func testRecentActivity() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PersonModel.self, DebtRecordModel.self, PaymentModel.self,
            configurations: config
        )
        let context = container.mainContext
        let person = PersonModel(name: "Ahmet")
        context.insert(person)
        let debt = DebtRecordModel(personID: person.id, amount: 500,
                                    kindRawValue: "TRY", directionRawValue: "receivable")
        context.insert(debt)
        try context.save()

        let personRepo = PersonRepository(modelContext: context)
        let debtRepo = DebtRepository(modelContext: context)
        let balanceRepo = BalanceRepository(modelContext: context)
        let vm = DashboardViewModel(
            personRepo: personRepo,
            debtRepo: debtRepo,
            balanceRepo: balanceRepo,
            rateClient: MockRateProvider()
        )
        await vm.loadData()

        #expect(!vm.recentActivity.isEmpty)
        #expect(vm.recentActivity.first?.personName == "Ahmet")
    }

    @MainActor
    @Test("Monthly stats track person and debt counts")
    func testMonthlyStats() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PersonModel.self, DebtRecordModel.self, PaymentModel.self,
            configurations: config
        )
        let context = container.mainContext
        let person = PersonModel(name: "Test")
        context.insert(person)
        let debt = DebtRecordModel(personID: person.id, amount: 300,
                                    kindRawValue: "USD", directionRawValue: "payable")
        context.insert(debt)
        try context.save()

        let personRepo = PersonRepository(modelContext: context)
        let debtRepo = DebtRepository(modelContext: context)
        let balanceRepo = BalanceRepository(modelContext: context)
        let vm = DashboardViewModel(
            personRepo: personRepo,
            debtRepo: debtRepo,
            balanceRepo: balanceRepo,
            rateClient: MockRateProvider()
        )
        await vm.loadData()

        #expect(vm.monthlyStats.totalPersonCount == 1)
        #expect(vm.monthlyStats.activePersonCount >= 1)
    }

    @MainActor
    @Test("Currency distribution groups by CurrencyKind")
    func testCurrencyDistribution() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PersonModel.self, DebtRecordModel.self, PaymentModel.self,
            configurations: config
        )
        let context = container.mainContext
        let person = PersonModel(name: "Test")
        context.insert(person)
        let tryDebt = DebtRecordModel(personID: person.id, amount: 1000,
                                       kindRawValue: "TRY", directionRawValue: "receivable")
        context.insert(tryDebt)
        try context.save()

        let personRepo = PersonRepository(modelContext: context)
        let debtRepo = DebtRepository(modelContext: context)
        let balanceRepo = BalanceRepository(modelContext: context)
        let vm = DashboardViewModel(
            personRepo: personRepo,
            debtRepo: debtRepo,
            balanceRepo: balanceRepo,
            rateClient: MockRateProvider()
        )
        await vm.loadData()

        #expect(!vm.currencyDistribution.isEmpty)
        #expect(vm.currencyDistribution.contains(where: { $0.kind == .tryCoin }))
    }

    @MainActor
    @Test("Financial health score is calculated based on overdue debts and bakiye ratios")
    func testFinancialHealthScore() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PersonModel.self, DebtRecordModel.self, PaymentModel.self,
            configurations: config
        )
        let context = container.mainContext
        
        let person = PersonModel(name: "Mehmet")
        context.insert(person)
        try context.save()
        
        // Add an overdue debt (past due date)
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let overdueDebt = DebtRecordModel(
            personID: person.id,
            amount: 200,
            kindRawValue: "TRY",
            directionRawValue: "payable",
            dueDate: pastDate
        )
        context.insert(overdueDebt)
        try context.save()
        
        let personRepo = PersonRepository(modelContext: context)
        let debtRepo = DebtRepository(modelContext: context)
        let balanceRepo = BalanceRepository(modelContext: context)
        let vm = DashboardViewModel(
            personRepo: personRepo,
            debtRepo: debtRepo,
            balanceRepo: balanceRepo,
            rateClient: MockRateProvider()
        )
        await vm.loadData()
        
        // We have 1 overdue debt -> should deduct 15 points
        // We have only payables -> should deduct 20 points
        // Expected score: 100 - 15 - 20 = 65 -> Warning status
        #expect(vm.financialHealthScore == 65)
        #expect(vm.healthDetails.status == .warning)
    }
}
