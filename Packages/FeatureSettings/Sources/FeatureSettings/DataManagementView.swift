import SwiftUI
import SwiftData
import DesignSystem
import Core
import Domain
import Data
import Observability

// MARK: - Data Management View

public struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showDeleteSecondConfirm = false
    @State private var isExporting = false
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false
    @State private var showUndo = false
    @State private var deletedDataBackup: DeletedDataBackup?
    @State private var showExportWarning = false
    @State private var pendingExportAction: (() async -> Void)?

    private let exportService = DataExportService()
    private let analytics: any AnalyticsTracking = AnalyticsService.shared
    private let personRepo: FetchPersonsUseCase
    private let debtRepo: FetchDebtsForPersonUseCase

    public init(
        personRepo: FetchPersonsUseCase,
        debtRepo: FetchDebtsForPersonUseCase
    ) {
        self.personRepo = personRepo
        self.debtRepo = debtRepo
    }

    public var body: some View {
        List {
            // Export section
            Section {
                Button {
                    pendingExportAction = { await exportCSV() }
                    showExportWarning = true
                } label: {
                    Label(
                        "data.export.csv",
                        systemImage: "tablecells"
                    )
                }

                Button {
                    pendingExportAction = { await exportPDF() }
                    showExportWarning = true
                } label: {
                    Label(
                        "data.export.pdf",
                        systemImage: "doc.richtext"
                    )
                }
            } header: {
                Text("data.section.export")
            }

            // Delete section
            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label(
                        "data.delete.allData",
                        systemImage: "trash"
                    )
                }
            } header: {
                Text("data.section.danger")
            }
        }
        .navigationTitle("data.navigationTitle")
        .alert(
            "data.delete.confirmTitle",
            isPresented: $showDeleteConfirmation
        ) {
            Button("data.delete.cancel", role: .cancel) {}
            Button("data.delete.continue", role: .destructive) {
                showDeleteSecondConfirm = true
            }
        } message: {
            Text("data.delete.confirmMessage")
        }
        .alert(
            "data.export.warningTitle",
            isPresented: $showExportWarning
        ) {
            Button("data.export.cancel", role: .cancel) {
                pendingExportAction = nil
            }
            Button("data.export.continue") {
                Task { await pendingExportAction?() }
            }
        } message: {
            Text("data.export.warningMessage")
        }
        .alert(
            "data.delete.finalTitle",
            isPresented: $showDeleteSecondConfirm
        ) {
            Button("data.delete.cancel", role: .cancel) {}
            Button("data.delete.confirm", role: .destructive) {
                Task { await deleteAllData() }
            }
        } message: {
            Text("data.delete.finalMessage")
        }
        .overlay(alignment: .bottom) {
            if showUndo {
                UndoToastView(
                    message: "data.delete.undoMessage",
                    undoLabel: "data.delete.undo",
                    undoAction: { Task { await undoDelete() } },
                    onDismiss: { showUndo = false; deletedDataBackup = nil }
                )
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedFileURL {
                #if canImport(UIKit)
                ShareSheet(activityItems: [url])
                #endif
            }
        }
    }

    // MARK: - Actions

    private func exportCSV() async {
        let rows = await fetchExportRows()
        guard !rows.isEmpty else { return }
        if let data = try? exportService.exportAsCSV(rows: rows) {
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("Vade_Export.csv")
            try? data.write(to: fileURL)
            exportedFileURL = fileURL
            showShareSheet = true
            analytics.track(.exportUsed(format: "csv"))
        }
    }

    private func exportPDF() async {
        let rows = await fetchExportRows()
        guard !rows.isEmpty else { return }
        if let data = try? exportService.exportAsPDF(rows: rows) {
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("Vade_Export.pdf")
            try? data.write(to: fileURL)
            exportedFileURL = fileURL
            showShareSheet = true
            analytics.track(.exportUsed(format: "pdf"))
        }
    }

    private func deleteAllData() async {
        let context = modelContext
        do {
            // Backup all data before deletion for undo support
            let persons = try context.fetch(FetchDescriptor<PersonModel>())
            let debts = try context.fetch(FetchDescriptor<DebtRecordModel>())
            let payments = try context.fetch(FetchDescriptor<PaymentModel>())
            let audits = try context.fetch(FetchDescriptor<AuditEntryModel>())

            deletedDataBackup = DeletedDataBackup(
                persons: persons, debts: debts, payments: payments, audits: audits
            )

            for person in persons { context.delete(person) }
            for debt in debts { context.delete(debt) }
            for payment in payments { context.delete(payment) }
            for audit in audits { context.delete(audit) }

            try context.save()
            showUndo = true
            analytics.track(.dataDeleted)
        } catch {
            AppLog.data.error("[DataManagement] Delete failed: \(error.localizedDescription)")
        }
    }

    private func undoDelete() async {
        guard let backup = deletedDataBackup else { return }
        let context = modelContext
        for person in backup.persons { context.insert(person) }
        for debt in backup.debts { context.insert(debt) }
        for payment in backup.payments { context.insert(payment) }
        for audit in backup.audits { context.insert(audit) }
        do {
            try context.save()
            deletedDataBackup = nil
            showUndo = false
        } catch {
            AppLog.data.error("[DataManagement] Undo failed: \(error.localizedDescription)")
        }
    }

    private func fetchExportRows() async -> [ExportRow] {
        guard let persons = try? await personRepo.execute(includeArchived: true) else { return [] }

        var rows: [ExportRow] = []
        for person in persons {
            guard let debts = try? await debtRepo.execute(for: person.id) else { continue }
            for debt in debts {
                rows.append(ExportRow(
                    personName: person.name,
                    amount: debt.amount,
                    currency: debt.kind.displayName,
                    direction: debt.direction == .receivable
                        ? "export.direction.receivable" : "export.direction.payable",
                    dueDate: debt.dueDate,
                    status: debt.status.rawValue,
                    createdAt: debt.createdAt
                ))
            }
        }
        return rows
    }
}

// MARK: - Deleted Data Backup (for undo)

private struct DeletedDataBackup {
    let persons: [PersonModel]
    let debts: [DebtRecordModel]
    let payments: [PaymentModel]
    let audits: [AuditEntryModel]
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

// Preview disabled: requires repository injection.
