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
    @State private var exportedData: Data?
    @State private var showShareSheet = false
    @State private var showUndo = false
    @State private var deletedDataBackup: DeletedDataBackup?

    private let exportService = DataExportService()
    @State private var analytics: any AnalyticsTracking = AnalyticsService()

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
                    undoAction: { Task { await undoDelete() } },
                    onDismiss: { showUndo = false; deletedDataBackup = nil }
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
            analytics.track(.exportUsed(format: .csv))
        }
    }

    private func exportPDF() async {
        let rows = await fetchExportRows()
        guard !rows.isEmpty else { return }
        if let data = try? exportService.exportAsPDF(rows: rows) {
            exportedData = data
            showShareSheet = true
            analytics.track(.exportUsed(format: .pdf))
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
        // Uses MainActor-isolated context — safe from within View body
        let repo = PersonRepository(modelContext: modelContext)
        guard let persons = try? await repo.execute(includeArchived: true) else { return [] }
        let debtRepo = DebtRepository(modelContext: modelContext)

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
