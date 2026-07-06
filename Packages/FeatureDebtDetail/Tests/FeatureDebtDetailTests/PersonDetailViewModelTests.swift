import Foundation
import Testing
import SwiftData
import Domain
@testable import FeatureDebtDetail
@testable import Data

@Suite("PersonDetailViewModel")
struct PersonDetailViewModelTests {

    @MainActor
    @Test("Initial state loads debts and computes balance")
    func testLoadData() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PersonModel.self, DebtRecordModel.self, PaymentModel.self,
            configurations: config
        )
        let context = container.mainContext

        let person = PersonModel(name: "Can")
        context.insert(person)
        try context.save()

        let debt = DebtRecordModel(personID: person.id, amount: 2000,
                                    kindRawValue: "TRY", directionRawValue: "receivable")
        context.insert(debt)
        try context.save()

        let vm = PersonDetailViewModel(
            person: person.toDomain(),
            modelContext: context
        )
        await vm.loadData()

        #expect(vm.debts.count == 1)
        #expect(vm.debts.first?.amount == 2000)
        #expect(vm.balance == 2000)
    }

    @MainActor
    @Test("Adding a debt updates the list")
    func testAddDebt() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PersonModel.self, DebtRecordModel.self, PaymentModel.self,
            configurations: config
        )
        let context = container.mainContext

        let person = PersonModel(name: "Deniz")
        context.insert(person)
        try context.save()

        let vm = PersonDetailViewModel(
            person: person.toDomain(),
            modelContext: context
        )
        await vm.loadData()
        #expect(vm.debts.isEmpty)

        await vm.addDebt(amount: 750, kind: .tryCoin, direction: .receivable, note: "Test", dueDate: nil)
        #expect(vm.debts.count == 1)
        #expect(vm.debts.first?.amount == 750)
    }

    @MainActor
    @Test("Recording a payment updates the balance")
    func testRecordPayment() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PersonModel.self, DebtRecordModel.self, PaymentModel.self,
            configurations: config
        )
        let context = container.mainContext

        let person = PersonModel(name: "Ece")
        context.insert(person)
        try context.save()

        let debt = DebtRecordModel(personID: person.id, amount: 1000,
                                    kindRawValue: "TRY", directionRawValue: "receivable")
        context.insert(debt)
        try context.save()

        let vm = PersonDetailViewModel(
            person: person.toDomain(),
            modelContext: context
        )
        await vm.loadData()
        #expect(vm.balance == 1000)

        await vm.recordPayment(debtRecordID: debt.id, amount: 300, note: nil)
        #expect(vm.balance == 700)
    }
}
