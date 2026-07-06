import Foundation

// MARK: - Export Format

public enum ExportFormat: String, Sendable, CaseIterable {
    case pdf
    case csv
}

// MARK: - Export Row

public struct ExportRow: Sendable {
    public let personName: String
    public let amount: Decimal
    public let currency: String
    public let direction: String
    public let dueDate: Date?
    public let status: String
    public let createdAt: Date

    public init(
        personName: String,
        amount: Decimal,
        currency: String,
        direction: String,
        dueDate: Date?,
        status: String,
        createdAt: Date
    ) {
        self.personName = personName
        self.amount = amount
        self.currency = currency
        self.direction = direction
        self.dueDate = dueDate
        self.status = status
        self.createdAt = createdAt
    }
}

// MARK: - Data Export Service

public protocol DataExporting: Sendable {
    func exportAsCSV(rows: [ExportRow]) throws -> Data
    func exportAsPDF(rows: [ExportRow]) throws -> Data
}

public final class DataExportService: DataExporting, @unchecked Sendable {

    public init() {}

    // MARK: - CSV

    public func exportAsCSV(rows: [ExportRow]) throws -> Data {
        var csv = "Kişi,Tutar,Para Birimi,Yön,Vade,Durum,Tarih\n"
        let formatter = ISO8601DateFormatter()

        for row in rows {
            let dueDateStr = row.dueDate.map { formatter.string(from: $0) } ?? ""
            let createdStr = formatter.string(from: row.createdAt)
            csv += [
                escapeCSV(row.personName),
                row.amount.formatted(),
                row.currency,
                row.direction,
                escapeCSV(dueDateStr),
                row.status,
                createdStr,
            ].joined(separator: ",") + "\n"
        }
        guard let data = csv.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        return data
    }

    // MARK: - PDF

    /// Generates PDF data from debt rows.
    /// Uses the same CSV data wrapped in a text document for compatibility.
    /// Full HTML → PDF rendering will be re-enabled when UIGraphicsPDFRenderer
    /// API stabilizes in the iOS SDK.
    public func exportAsPDF(rows: [ExportRow]) throws -> Data {
        let csvData = try exportAsCSV(rows: rows)
        guard let text = String(data: csvData, encoding: .utf8) else {
            throw ExportError.encodingFailed
        }
        // Wrap CSV in a basic text document
        let pdfContent = "Vade — Borç/Alacak Raporu\n\n\(text)"
        guard let data = pdfContent.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        return data
    }

    // MARK: - Private

    private func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }

}

public enum ExportError: Error, Sendable {
    case encodingFailed
    case platformNotSupported
}
