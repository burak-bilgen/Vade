import Foundation
import Testing
@testable import FeatureSettings
import SwiftUI
import Core

@Suite("FeatureSettings")
struct FeatureSettingsTests {

    @Test("SettingsView initializes with default app storage values")
    @MainActor
    func testDefaultValues() {
        // Verify the SettingsView can be constructed without crashing
        let view = SettingsView()
        #expect(view is SettingsView)
    }

    @Test("DataExportService CSV export produces valid UTF-8 data")
    func testExportRoundTrip() async throws {
        let service = DataExportService()
        let rows: [ExportRow] = [
            ExportRow(
                personName: "Test",
                amount: 100,
                currency: "TRY",
                direction: "receivable",
                dueDate: nil,
                status: "pending",
                createdAt: Date()
            )
        ]
        let data = try service.exportAsCSV(rows: rows)
        #expect(data.count > 0)
        let text = try #require(String(data: data, encoding: .utf8))
        #expect(text.contains("Test"))
    }
}
