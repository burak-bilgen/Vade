import Foundation
import Testing
import SwiftData
@testable import FeatureDashboard
@testable import Data

@Suite("PeopleListViewModel")
struct PeopleListViewModelTests {

    @MainActor
    @Test("Loads persons and computes balances")
    func testLoadPersons() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PersonModel.self, DebtRecordModel.self, PaymentModel.self,
            configurations: config
        )
        let context = container.mainContext

        let person = PersonModel(name: "Ayşe")
        context.insert(person)
        try context.save()

        let receivable = DebtRecordModel(personID: person.id, amount: 1500,
                                          kindRawValue: "TRY", directionRawValue: "receivable")
        context.insert(receivable)
        try context.save()

        let vm = PeopleListViewModel(modelContext: context)
        await vm.loadPersons()

        #expect(vm.persons.count == 1)
        #expect(vm.persons.first?.name == "Ayşe")
        #expect(vm.personBalances[person.id] == 1500)
    }

    @MainActor
    @Test("Filtered persons shows only receivable when selected")
    func testFilteredReceivable() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PersonModel.self, DebtRecordModel.self, PaymentModel.self,
            configurations: config
        )
        let context = container.mainContext

        let p1 = PersonModel(name: "Ali")
        context.insert(p1)
        try context.save()

        let receivable = DebtRecordModel(personID: p1.id, amount: 1000,
                                          kindRawValue: "TRY", directionRawValue: "receivable")
        context.insert(receivable)
        try context.save()

        let vm = PeopleListViewModel(modelContext: context)
        await vm.loadPersons()
        vm.selectedSegment = .receivable

        #expect(vm.filteredPersons.count == 1)
        #expect(vm.filteredPersons.first?.balance == 1000)
    }

    @MainActor
    @Test("Filtered persons shows only payable when selected")
    func testFilteredPayable() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PersonModel.self, DebtRecordModel.self, PaymentModel.self,
            configurations: config
        )
        let context = container.mainContext

        let p1 = PersonModel(name: "Veli")
        context.insert(p1)
        try context.save()

        let payable = DebtRecordModel(personID: p1.id, amount: 500,
                                       kindRawValue: "TRY", directionRawValue: "payable")
        context.insert(payable)
        try context.save()

        let vm = PeopleListViewModel(modelContext: context)
        await vm.loadPersons()
        vm.selectedSegment = .payable

        #expect(vm.filteredPersons.count == 1)
        #expect(vm.filteredPersons.first?.balance == 500)
    }

    @MainActor
    @Test("Add person appends to list and refreshes")
    func testAddPerson() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PersonModel.self, DebtRecordModel.self, PaymentModel.self,
            configurations: config
        )
        let vm = PeopleListViewModel(modelContext: container.mainContext)
        await vm.loadPersons()
        #expect(vm.persons.isEmpty)

        await vm.addPerson(name: "Mehmet", phoneNumber: "555", notes: nil)
        #expect(vm.persons.count == 1)
        #expect(vm.persons.first?.name == "Mehmet")
    }
}
