import SwiftUI
import SwiftData
import DesignSystem
import Core
import Domain

// MARK: - Data Management View

public struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showDeleteSecondConfirm = false
    @State private var isExporting = false
    @State private var exportedData: Data?
    @State private var showShareSheet = false
    @State private var showUndo = false

    private let exportService = DataExportService()

    public init() {}

    public var body: some View {
        List {
            // Export section
            Section {
                Button {
                    Task { await exportCSV() }
                } label: {
                    Label(
                        String(localized: "data.export.csv"),
                        systemImage: "tablecells"
                    )
                }

                Button {
                    Task { await exportPDF() }
                } label: {
                    Label(
                        String(localized: "data.export.pdf"),
                        systemImage: "doc.richtext"
                    )
                }
            } header: {
                Text(String(localized: "data.section.export"))
            }

            // Delete section
            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label(
                        String(localized: "data.delete.allData"),
                        systemImage: "trash"
                    )
                }
            } header: {
                Text(String(localized: "data.section.danger"))
            }
        }
        .navigationTitle(String(localized: "data.navigationTitle"))
        .alert(
            String(localized: "data.delete.confirmTitle"),
            isPresented: $showDeleteConfirmation
        ) {
            Button(String(localized: "data.delete.cancel"), role: .cancel) {}
            Button(String(localized: "data.delete.continue"), role: .destructive) {
                showDeleteSecondConfirm = true
            }
        } message: {
            Text(String(localized: "data.delete.confirmMessage"))
        }
        .alert(
            String(localized: "data.delete.finalTitle"),
            isPresented: $showDeleteSecondConfirm
        ) {
            Button(String(localized: "data.delete.cancel"), role: .cancel) {}
            Button(String(localized: "data.delete.confirm"), role: .destructive) {
                Task { await deleteAllData() }
            }
        } message: {
            Text(String(localized: "data.delete.finalMessage"))
        }
        .overlay(alignment: .bottom) {
            if showUndo {
                UndoToastView(
                    message: String(localized: "data.delete.undoMessage"),
                    undoLabel: String(localized: "data.delete.undo"),
                    undoAction: { showUndo = false },
                    onDismiss: { showUndo = false }
                )
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = exportedData {
                #if canImport(UIKit)
                ShareSheet(activityItems: [data])
                #endif
            }
        }
    }

    // MARK: - Actions

    private func exportCSV() async {
        let rows = await fetchExportRows()
        guard !rows.isEmpty else { return }
        if let data = try? exportService.exportAsCSV(rows: rows) {
            exportedData = data
            showShareSheet = true
        }
    }

    private func exportPDF() async {
        let rows = await fetchExportRows()
        guard !rows.isEmpty else { return }
        if let data = try? exportService.exportAsPDF(rows: rows) {
            exportedData = data
            showShareSheet = true
        }
    }

    private func deleteAllData() async {
        // Delete all SwiftData objects
        let context = modelContext
        do {
            try context.delete(model: PersonModel.self)
            try context.delete(model: DebtRecordModel.self)
            try context.delete(model: PaymentModel.self)
            try context.delete(model: AuditEntryModel.self)
            try context.save()
            showUndo = true
        } catch {
            AppLog.data.error("[DataManagement] Delete failed: \(error.localizedDescription)")
        }
    }

    private func fetchExportRows() async -> [ExportRow] {
        let personRepo = PersonRepository(modelContext: modelContext)
        let debtRepo = DebtRepository(modelContext: modelContext)

        guard let persons = try? await personRepo.execute(includeArchived: true) else { return [] }
        var rows: [ExportRow] = []

        for person in persons {
            guard let debts = try? await debtRepo.execute(for: person.id) else { continue }
            for debt in debts {
                rows.append(ExportRow(
                    personName: person.name,
                    amount: debt.amount,
                    currency: debt.kind.rawValue,
                    direction: debt.direction == .receivable
                        ? String(localized: "export.direction.receivable")
                        : String(localized: "export.direction.payable"),
                    dueDate: debt.dueDate,
                    status: debt.status.rawValue,
                    createdAt: debt.createdAt
                ))
            }
        }
        return rows
    }
}

// MARK: - Share Sheet (UIKit bridge)

#if canImport(UIKit)
private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
