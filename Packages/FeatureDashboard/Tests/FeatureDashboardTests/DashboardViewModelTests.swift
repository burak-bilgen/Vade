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
        let vm = DashboardViewModel(modelContext: container.mainContext, rateClient: MockRateProvider())
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

        let person = PersonModel(name: "Test")
        context.insert(person)
        try context.save()

        let receivable = DebtRecordModel(personID: person.id, amount: 1000,
                                          kindRawValue: "TRY", directionRawValue: "receivable")
        let payable = DebtRecordModel(personID: person.id, amount: 500,
                                       kindRawValue: "TRY", directionRawValue: "payable")
        context.insert(receivable)
        context.insert(payable)
        try context.save()

        let vm = DashboardViewModel(modelContext: context, rateClient: MockRateProvider())
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

        let vm = DashboardViewModel(modelContext: context, rateClient: MockRateProvider())
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

        let vm = DashboardViewModel(modelContext: context, rateClient: MockRateProvider())
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

        let vm = DashboardViewModel(modelContext: context, rateClient: MockRateProvider())
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

        let vm = DashboardViewModel(modelContext: context, rateClient: MockRateProvider())
        await vm.loadData()

        #expect(!vm.currencyDistribution.isEmpty)
        #expect(vm.currencyDistribution.contains(where: { $0.kind == .tryCoin }))
    }
}
