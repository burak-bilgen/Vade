import Foundation
import Testing
@testable import Core

@MainActor
@Suite("DataExportService")
struct DataExportServiceTests {

    @Test("CSV export produces valid data with headers")
    func testCSVExport() throws {
        let service = DataExportService()
        let rows = [
            ExportRow(personName: "Ahmet", amount: 1500, currency: "TRY",
                      direction: "Alacak", dueDate: nil, status: "pending",
                      createdAt: Date()),
            ExportRow(personName: "Ayşe", amount: 750, currency: "USD",
                      direction: "Borç", dueDate: Date(), status: "pending",
                      createdAt: Date()),
        ]

        let data = try service.exportAsCSV(rows: rows)
        let csv = String(data: data, encoding: .utf8)!

        #expect(csv.contains("export.csv.header"))
        #expect(csv.contains("Ahmet"))
        #expect(csv.contains("Ayşe"))
        #expect(csv.contains("Ahmet"))
        #expect(csv.contains("USD"))
    }

    @Test("CSV export escapes fields with commas")
    func testCSVEscaping() throws {
        let service = DataExportService()
        let rows = [
            ExportRow(personName: "Ali, Mehmet", amount: 100, currency: "TRY",
                      direction: "Alacak", dueDate: nil, status: "pending",
                      createdAt: Date()),
        ]
        let data = try service.exportAsCSV(rows: rows)
        let csv = String(data: data, encoding: .utf8)!
        #expect(csv.contains("\"Ali, Mehmet\""))
    }

    @Test("CSV export with empty rows produces header only")
    func testCSVEmpty() throws {
        let service = DataExportService()
        let data = try service.exportAsCSV(rows: [])
        let csv = String(data: data, encoding: .utf8)!
        let lines = csv.split(separator: "\n")
        #expect(lines.count == 1)
        #expect(lines[0].contains("export.csv.header"))
    }
}
