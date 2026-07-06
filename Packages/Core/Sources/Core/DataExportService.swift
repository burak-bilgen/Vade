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

    // MARK: - PDF (Simple HTML → PDF via UIMarkupTextPrintFormatter)

    public func exportAsPDF(rows: [ExportRow]) throws -> Data {
        #if canImport(UIKit)
        let html = buildHTML(rows: rows)
        let printFormatter = UIMarkupTextPrintFormatter(markupText: html)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))

        return renderer.pdfData { context in
            context.beginPage()
            let rect = CGRect(x: 40, y: 40, width: 515, height: 762)
            printFormatter.draw(in: rect)
        }
        #else
        throw ExportError.platformNotSupported
        #endif
    }

    // MARK: - Private

    private func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }

    private func buildHTML(rows: [ExportRow]) -> String {
        var html = """
        <html><head><meta charset="utf-8"><style>
        body { font-family: -apple-system; font-size: 11pt; }
        table { width: 100%%; border-collapse: collapse; }
        th { background: #1B2340; color: white; padding: 8px; text-align: left; }
        td { padding: 6px 8px; border-bottom: 1px solid #E3E5EC; }
        </style></head><body>
        <h1>Vade — Borç/Alacak Raporu</h1>
        <table><tr><th>Kişi</th><th>Tutar</th><th>Birim</th><th>Yön</th><th>Vade</th><th>Durum</th></tr>
        """
        for row in rows {
            let dueStr = row.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "-"
            html += "<tr><td>\(row.personName)</td><td>\(row.amount.formatted())</td><td>\(row.currency)</td><td>\(row.direction)</td><td>\(dueStr)</td><td>\(row.status)</td></tr>"
        }
        html += "</table></body></html>"
        return html
    }
}

public enum ExportError: Error, Sendable {
    case encodingFailed
    case platformNotSupported
}
