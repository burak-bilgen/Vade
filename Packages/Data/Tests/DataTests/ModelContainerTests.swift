import Foundation
import Testing
import SwiftData
@testable import Data

@Suite("SwiftData Model Container")
struct ModelContainerTests {

    @Test("ModelContainer creates successfully with CloudKit schema")
    func testModelContainerCreation() throws {
        let schema = Schema([
            PersonModel.self,
            DebtRecordModel.self,
            PaymentModel.self,
            AuditEntryModel.self,
        ])

        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        #expect(container.schema != nil)
    }

    @Test("PersonModel inserts and fetches correctly")
    @MainActor
    func testPersonModelInsert() throws {
        let schema = Schema([PersonModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let person = PersonModel(name: "Ayşe", phoneNumber: "+905551234567")
        context.insert(person)
        try context.save()

        let descriptor = FetchDescriptor<PersonModel>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results.first?.name == "Ayşe")
    }

    @Test("DebtRecordModel stores decimal amount precisely")
    @MainActor
    func testDebtRecordDecimalPrecision() throws {
        let schema = Schema([DebtRecordModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let debt = DebtRecordModel(personID: UUID(), amount: 333.33)
        context.insert(debt)
        try context.save()

        let results = try context.fetch(FetchDescriptor<DebtRecordModel>())
        #expect(results.first?.amount == 333.33)
    }
}
