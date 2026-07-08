import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Export Format

/// Canonical ExportFormat definition. Domain tracks export via String rawValue.
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

@MainActor
public protocol DataExporting: Sendable {
    func exportAsCSV(rows: [ExportRow]) throws -> Data
    func exportAsPDF(rows: [ExportRow]) throws -> Data
}

@MainActor
public final class DataExportService: DataExporting {

    public init() {}

    // MARK: - CSV

    public func exportAsCSV(rows: [ExportRow]) throws -> Data {
        let header = LanguageManager.shared.localized("export.csv.header")
        var csv = header + "\n"
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

    /// Generates a real PDF document from debt rows using UIGraphicsPDFRenderer.
    /// iOS-only — uses UIKit PDF rendering.
    public func exportAsPDF(rows: [ExportRow]) throws -> Data {
        #if canImport(UIKit)
        return try renderPDF(rows: rows)
        #else
        throw ExportError.encodingFailed
        #endif
    }

    #if canImport(UIKit)
    private func renderPDF(rows: [ExportRow]) throws -> Data {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        let pageWidth: CGFloat = 612   // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 48

        let title = LanguageManager.shared.localized("export.pdf.title")
        let generatedDate = formatter.string(from: Date())

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { ctx in
            ctx.beginPage()

            var yOffset: CGFloat = margin

            // ── Title ──
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 22),
                .foregroundColor: UIColor.label
            ]
            title.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: titleAttrs)
            yOffset += 32

            // ── Generated date ──
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.secondaryLabel
            ]
            generatedDate.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: dateAttrs)
            yOffset += 20

            // ── Separator ──
            ctx.cgContext.setStrokeColor(UIColor.separator.cgColor)
            ctx.cgContext.setLineWidth(0.5)
            ctx.cgContext.move(to: CGPoint(x: margin, y: yOffset))
            ctx.cgContext.addLine(to: CGPoint(x: pageWidth - margin, y: yOffset))
            ctx.cgContext.strokePath()
            yOffset += 16

            // ── Table header ──
            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 9),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let columns: [(String, CGFloat)] = [
                (LanguageManager.shared.localized("export.pdf.col.person"), 120),
                (LanguageManager.shared.localized("export.pdf.col.amount"), 70),
                (LanguageManager.shared.localized("export.pdf.col.currency"), 50),
                (LanguageManager.shared.localized("export.pdf.col.direction"), 60),
                (LanguageManager.shared.localized("export.pdf.col.dueDate"), 80),
                (LanguageManager.shared.localized("export.pdf.col.status"), 60),
            ]
            var colX: CGFloat = margin
            for (header, width) in columns {
                header.draw(at: CGPoint(x: colX, y: yOffset), withAttributes: headerAttrs)
                colX += width
            }
            yOffset += 14

            // ── Separator ──
            ctx.cgContext.setStrokeColor(UIColor.separator.cgColor)
            ctx.cgContext.setLineWidth(0.5)
            ctx.cgContext.move(to: CGPoint(x: margin, y: yOffset))
            ctx.cgContext.addLine(to: CGPoint(x: pageWidth - margin, y: yOffset))
            ctx.cgContext.strokePath()
            yOffset += 8

            // ── Rows ──
            let rowAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor.label
            ]
            for row in rows {
                // Check page break
                if yOffset > pageHeight - margin {
                    ctx.beginPage()
                    yOffset = margin
                }

                let dueDateStr = row.dueDate.map { formatter.string(from: $0) } ?? "-"
                let values: [String] = [
                    row.personName,
                    row.amount.formatted(),
                    row.currency,
                    row.direction,
                    dueDateStr,
                    row.status,
                ]
                colX = margin
                for (i, value) in values.enumerated() {
                    let width = i < columns.count ? columns[i].1 : 80
                    value.draw(at: CGPoint(x: colX, y: yOffset), withAttributes: rowAttrs)
                    colX += width
                }
                yOffset += 16
            }

            // ── Footer ──
            yOffset = pageHeight - margin - 16
            ctx.cgContext.setStrokeColor(UIColor.separator.cgColor)
            ctx.cgContext.setLineWidth(0.5)
            ctx.cgContext.move(to: CGPoint(x: margin, y: yOffset))
            ctx.cgContext.addLine(to: CGPoint(x: pageWidth - margin, y: yOffset))
            ctx.cgContext.strokePath()
            yOffset += 8

            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor.tertiaryLabel
            ]
            let footerText = LanguageManager.shared.localized("export.pdf.footer")
            let recordCountText = LanguageManager.shared.localized("export.pdf.recordCount")
            (footerText + " — \(rows.count) " + recordCountText).draw(
                at: CGPoint(x: margin, y: yOffset), withAttributes: footerAttrs
            )
        }
    }
    #endif

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
}
