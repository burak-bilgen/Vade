import SwiftUI
import SwiftData
import DesignSystem
import Domain
import Data
import Observability

// MARK: - Person Detail View

public struct PersonDetailView: View {
    let person: Person
    let modelContext: ModelContext
    @State private var viewModel: PersonDetailViewModel?
    @State private var showAddDebt = false
    @State private var selectedDebt: DebtRecord?
    @State private var analytics: any AnalyticsTracking = AnalyticsService()

    public init(person: Person, modelContext: ModelContext) {
        self.person = person
        self.modelContext = modelContext
    }

    public var body: some View {
        Group {
            if let vm = viewModel {
                contentView(vm)
            } else {
                ProgressView()
                    .task {
                        let vm = PersonDetailViewModel(person: person, modelContext: modelContext, analytics: analytics)
                        viewModel = vm
                        await vm.loadData()
                    }
            }
        }
        .background(ColorTokens.background)
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(String(localized: "personDetail.addDebt.button"), systemImage: "plus") {
                    showAddDebt = true
                }
            }
        }
        .sheet(isPresented: $showAddDebt) {
            AddDebtSheet(person: person, analytics: analytics) { amount, kind, direction, note, dueDate in
                await viewModel?.addDebt(amount: amount, kind: kind, direction: direction, note: note, dueDate: dueDate)
                showAddDebt = false
            }
        }
        .sheet(item: $selectedDebt) { debt in
            RecordPaymentSheet(debt: debt) { amount, note in
                await viewModel?.recordPayment(debtRecordID: debt.id, amount: amount, note: note)
                selectedDebt = nil
            }
        }
        .refreshable { await viewModel?.loadData() }
    }

    // MARK: - Content

    @ViewBuilder
    private func contentView(_ vm: PersonDetailViewModel) -> some View {
        ScrollView {
            VStack(spacing: Spacing.l) {
                // ✦ Balance header — Glassmorphism card
                VStack(spacing: Spacing.xs) {
                    Text(String(localized: "personDetail.balance.label"))
                        .font(Typography.font(for: .label))
                        .foregroundStyle(ColorTokens.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    Text(vm.balance.formatted())
                        .font(Typography.font(for: .displayMedium))
                        .foregroundStyle(balanceColor(vm.balance))
                        .contentTransition(.numericText(countsDown: true))
                        .minimumScaleFactor(0.85)

                    // Direction indicator
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: vm.balance >= 0 ? "arrow.up.forward" : "arrow.down.forward")
                            .font(.system(size: 10, weight: .bold))
                        Text(vm.balance >= 0
                            ? String(localized: "personDetail.balance.receivable")
                            : String(localized: "personDetail.balance.payable"))
                            .font(Typography.font(for: .caption))
                    }
                    .foregroundStyle(balanceColor(vm.balance))
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.xxs)
                    .background(balanceColor(vm.balance).opacity(0.12), in: .capsule)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.xxl)
                .glass(GlassStyle.standard)

                // Debt count summary
                HStack(spacing: Spacing.m) {
                    DebtSummaryChip(
                        count: vm.debts.filter { $0.status == .pending }.count,
                        label: String(localized: "personDetail.status.pending"),
                        color: ColorTokens.chartOrange
                    )
                    DebtSummaryChip(
                        count: vm.debts.filter { $0.status == .paid }.count,
                        label: String(localized: "personDetail.status.paid"),
                        color: ColorTokens.positive
                    )
                    DebtSummaryChip(
                        count: vm.debts.filter { $0.status == .archived }.count,
                        label: String(localized: "personDetail.status.archived"),
                        color: ColorTokens.textTertiary
                    )
                }
                .padding(.horizontal, Spacing.xl)

                // Timeline header
                HStack {
                    Text(String(localized: "personDetail.history.title"))
                        .font(Typography.font(for: .title2))
                        .foregroundStyle(ColorTokens.textPrimary)
                    Spacer()
                    Text("\(vm.debts.count)")
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textTertiary)
                        .padding(.horizontal, Spacing.s)
                        .padding(.vertical, Spacing.xxs)
                        .background(Capsule().fill(ColorTokens.surface))
                }
                .padding(.horizontal, Spacing.xl)

                // Timeline
                if vm.debts.isEmpty {
                    EmptyStateView(
                        title: String(localized: "personDetail.empty.title"),
                        subtitle: String(localized: "personDetail.empty.subtitle")
                    )
                    .padding(.top, Spacing.xxxl)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(vm.debts.enumerated()), id: \.element.id) { i, debt in
                            TimelineDebtRow(
                                debt: debt,
                                isLast: i == vm.debts.count - 1,
                                onTap: { if debt.status == .pending { selectedDebt = debt } }
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                }

                Spacer().frame(height: Spacing.xxxl)
            }
            .padding(.vertical, Spacing.l)
        }
        .background(ColorTokens.background)
    }

    // MARK: - Helpers

    private func balanceColor(_ balance: Decimal) -> Color {
        if balance.isEffectivelyZero { return ColorTokens.textPrimary }
        return balance > 0 ? ColorTokens.positive : ColorTokens.negative
    }
}

// MARK: - Debt Summary Chip

private struct DebtSummaryChip: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text("\(count)")
                .font(Typography.font(for: .title2))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(label)
                .font(Typography.font(for: .label))
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(ColorTokens.surface)
        )
    }
}

// MARK: - Timeline Debt Row

private struct TimelineDebtRow: View {
    let debt: DebtRecord
    let isLast: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Spacing.m) {
                // Timeline dot + line
                VStack(spacing: 0) {
                    Circle()
                        .fill(statusColor(debt.status))
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(ColorTokens.border, lineWidth: 1)
                        )
                    if !isLast {
                        Rectangle()
                            .fill(ColorTokens.border)
                            .frame(width: 1, height: 40)
                    }
                }

                // Card content
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack {
                        Text(debt.note ?? debt.kind.rawValue)
                            .font(Typography.font(for: .bodyEmphasis))
                            .foregroundStyle(ColorTokens.textPrimary)
                            .lineLimit(2)
                        Spacer()
                        Text(debt.amount.formatted())
                            .font(Typography.font(for: .amount))
                            .foregroundStyle(debt.direction == .receivable
                                ? ColorTokens.positive : ColorTokens.negative)
                            .contentTransition(.numericText())
                    }

                    // Meta row
                    HStack(spacing: Spacing.s) {
                        Label(debt.kind.rawValue, systemImage: debt.kind.isFiat ? "dollarsign" : "star")
                            .font(Typography.font(for: .caption))
                            .foregroundStyle(ColorTokens.textTertiary)

                        if let dueDate = debt.dueDate {
                            Label(dueDate.formatted(date: .abbreviated, time: .omitted),
                                  systemImage: "calendar")
                                .font(Typography.font(for: .caption))
                                .foregroundStyle(isOverdue(dueDate) ? ColorTokens.negative : ColorTokens.textTertiary)
                        }

                        Spacer()

                        // Status badge
                        Text(statusLabel(debt.status))
                            .font(Typography.font(for: .label))
                            .foregroundStyle(statusColor(debt.status))
                            .padding(.horizontal, Spacing.s)
                            .padding(.vertical, 2)
                            .background(statusColor(debt.status).opacity(0.12), in: .capsule)
                    }
                }
                .padding(Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .fill(ColorTokens.surface)
                )
                .elevation(Elevation.level1)
            }
            .opacity(debt.status == .pending ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(debt.status != .pending)
    }

    private func statusColor(_ status: DebtStatus) -> Color {
        switch status {
        case .pending: return ColorTokens.chartOrange
        case .paid: return ColorTokens.positive
        case .archived: return ColorTokens.textTertiary
        }
    }

    private func statusLabel(_ status: DebtStatus) -> String {
        switch status {
        case .pending: return String(localized: "personDetail.status.pending")
        case .paid: return String(localized: "personDetail.status.paid")
        case .archived: return String(localized: "personDetail.status.archived")
        }
    }

    private func isOverdue(_ date: Date) -> Bool {
        Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
    }
}

// MARK: - Add Debt Sheet (Premium)

private struct AddDebtSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    @State private var selectedKind: CurrencyKind = .tryCoin
    @State private var selectedDirection: DebtDirection = .receivable
    @State private var note = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var isSaving = false

    let person: Person
    let analytics: any AnalyticsTracking
    let onSave: (Decimal, CurrencyKind, DebtDirection, String?, Date?) async -> Void

    var parsedAmount: Decimal? { Decimal(string: amountText) }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                // Amount input — premium style
                VStack(spacing: Spacing.xxs) {
                    Text(String(localized: "debt.add.amountPlaceholder"))
                        .font(Typography.font(for: .label))
                        .foregroundStyle(ColorTokens.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    TextField("0,00", text: $amountText)
                        .font(Typography.font(for: .displayMedium))
                        .foregroundStyle(ColorTokens.textPrimary)
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .disabled(isSaving)
                }
                .padding(.top, Spacing.xl)

                // Currency picker as pill segments
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xxs) {
                        ForEach(CurrencyKind.allCases, id: \.self) { kind in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedKind = kind
                                }
                            } label: {
                                Text(kind.rawValue)
                                    .font(Typography.font(for: .buttonSmall))
                                    .foregroundStyle(selectedKind == kind
                                        ? (kind.isFiat ? ColorTokens.positive : ColorTokens.chartOrange)
                                        : ColorTokens.textTertiary)
                                    .padding(.horizontal, Spacing.m)
                                    .padding(.vertical, Spacing.s)
                                    .background(
                                        Capsule().fill(selectedKind == kind
                                            ? (kind.isFiat
                                                ? ColorTokens.positiveLight.opacity(0.2)
                                                : ColorTokens.chartOrange.opacity(0.2))
                                            : ColorTokens.surface)
                                    )
                            }
                            .disabled(isSaving)
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                }

                // Direction toggle pills
                HStack(spacing: Spacing.m) {
                    directionButton(.receivable, color: ColorTokens.positive)
                    directionButton(.payable, color: ColorTokens.negative)
                }
                .padding(.horizontal, Spacing.xl)

                // Note
                HStack(spacing: Spacing.m) {
                    Image(systemName: "note.text")
                        .foregroundStyle(ColorTokens.textTertiary)
                    TextField(String(localized: "debt.add.notePlaceholder"), text: $note)
                        .font(Typography.font(for: .body))
                        .disabled(isSaving)
                }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.ml)
                .background(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(ColorTokens.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(ColorTokens.border, lineWidth: 1)
                )
                .padding(.horizontal, Spacing.xl)

                // Due date toggle
                Toggle(isOn: $hasDueDate) {
                    Label(String(localized: "debt.add.dueDateToggle"), systemImage: "calendar")
                        .font(Typography.font(for: .body))
                }
                .tint(ColorTokens.accent)
                .disabled(isSaving)
                .padding(.horizontal, Spacing.xl)

                if hasDueDate {
                    DatePicker(
                        String(localized: "debt.add.dueDatePicker"),
                        selection: $dueDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding(.horizontal, Spacing.xl)
                }

                Spacer()

                // Save button
                Button {
                    Task { await save() }
                } label: {
                    HStack(spacing: Spacing.s) {
                        if isSaving { ProgressView().tint(.black) }
                        Text(String(localized: "debt.add.save"))
                            .font(Typography.font(for: .button))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        Capsule().fill(canSave ? ColorTokens.accent : ColorTokens.border)
                    )
                    .foregroundStyle(canSave && !isSaving ? .black : ColorTokens.textTertiary)
                }
                .disabled(!canSave || isSaving)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(ColorTokens.background)
            .navigationTitle(String(localized: "debt.add.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "debt.add.cancel")) { dismiss() }
                        .disabled(isSaving)
                }
            }
            .onChange(of: selectedKind) { _, newKind in
                analytics.track(.currencyChanged(to: newKind.analyticsCode))
            }
        }
    }

    private var canSave: Bool { (parsedAmount ?? .zero) > 0 }

    private func directionButton(_ direction: DebtDirection, color: Color) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { selectedDirection = direction }
        } label: {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: direction == .receivable ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                Text(direction == .receivable
                    ? String(localized: "debt.add.direction.receivable")
                    : String(localized: "debt.add.direction.payable"))
                    .font(Typography.font(for: .buttonSmall))
            }
            .foregroundStyle(selectedDirection == direction ? color : ColorTokens.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.m)
            .background(
                Capsule().fill(selectedDirection == direction
                    ? color.opacity(0.15) : ColorTokens.surface)
            )
        }
        .disabled(isSaving)
    }

    private func save() async {
        guard let amount = parsedAmount, amount > 0 else { return }
        isSaving = true
        await onSave(
            amount,
            selectedKind,
            selectedDirection,
            note.trimmed.isEmpty ? nil : note.trimmed,
            hasDueDate ? dueDate : nil
        )
        isSaving = false
    }
}

// MARK: - Record Payment Sheet (Premium)

private struct RecordPaymentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    @State private var note = ""
    @State private var isSaving = false

    let debt: DebtRecord
    let onSave: (Decimal, String?) async -> Void

    var parsedAmount: Decimal? { Decimal(string: amountText) }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.xxs) {
                    Text(String(localized: "payment.remainingBalance"))
                        .font(Typography.font(for: .label))
                        .foregroundStyle(ColorTokens.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Text(debt.amount.formatted())
                        .font(Typography.font(for: .displayMedium))
                        .foregroundStyle(debt.direction == .receivable
                            ? ColorTokens.positive : ColorTokens.negative)
                        .contentTransition(.numericText())
                }
                .padding(.top, Spacing.xxl)

                // Amount input
                VStack(spacing: Spacing.xxs) {
                    Text(String(localized: "payment.amountPlaceholder"))
                        .font(Typography.font(for: .label))
                        .foregroundStyle(ColorTokens.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    TextField("0,00", text: $amountText)
                        .font(Typography.font(for: .displayMedium))
                        .foregroundStyle(ColorTokens.textPrimary)
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .disabled(isSaving)
                }

                // Note
                HStack(spacing: Spacing.m) {
                    Image(systemName: "note.text")
                        .foregroundStyle(ColorTokens.textTertiary)
                    TextField(String(localized: "payment.notePlaceholder"), text: $note)
                        .font(Typography.font(for: .body))
                        .disabled(isSaving)
                }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.ml)
                .background(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(ColorTokens.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(ColorTokens.border, lineWidth: 1)
                )
                .padding(.horizontal, Spacing.xl)

                Spacer()

                // Full amount quick fill
                HStack(spacing: Spacing.m) {
                    quickFillButton(amount: debt.amount, label: String(localized: "payment.full"))
                    quickFillButton(amount: debt.amount / 2, label: String(localized: "payment.half"))
                    quickFillButton(amount: debt.amount / 4, label: String(localized: "payment.quarter"))
                }
                .padding(.horizontal, Spacing.xl)

                // Save
                Button {
                    Task { await save() }
                } label: {
                    HStack(spacing: Spacing.s) {
                        if isSaving { ProgressView().tint(.black) }
                        Text(String(localized: "payment.save"))
                            .font(Typography.font(for: .button))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        Capsule().fill(canSave ? ColorTokens.accent : ColorTokens.border)
                    )
                    .foregroundStyle(canSave && !isSaving ? .black : ColorTokens.textTertiary)
                }
                .disabled(!canSave || isSaving)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(ColorTokens.background)
            .navigationTitle(String(localized: "payment.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "payment.cancel")) { dismiss() }
                        .disabled(isSaving)
                }
            }
        }
    }

    private var canSave: Bool { (parsedAmount ?? .zero) > 0 }

    private func quickFillButton(amount: Decimal, label: String) -> some View {
        Button {
            amountText = amount.formatted()
        } label: {
            Text(label)
                .font(Typography.font(for: .buttonSmall))
                .foregroundStyle(ColorTokens.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s)
                .background(
                    Capsule().fill(ColorTokens.surface)
                )
                .overlay(
                    Capsule().stroke(ColorTokens.border, lineWidth: 1)
                )
        }
        .disabled(isSaving)
    }
}

// MARK: - Helpers

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

// MARK: - Preview

#if DEBUG
private let previewModelContainer: ModelContainer? = {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    do {
        return try ModelContainer(for: PersonModel.self, DebtRecordModel.self, PaymentModel.self, configurations: config)
    } catch {
        print("Failed to create preview ModelContainer: \(error.localizedDescription)")
        return nil
    }
}()

#Preview {
    NavigationStack {
        if let container = previewModelContainer {
            PersonDetailView(
                person: Person(name: "Ahmet"),
                modelContext: container.mainContext
            )
        } else {
            Text("Preview container could not be created")
                .foregroundStyle(ColorTokens.textTertiary)
        }
    }
}
#endif
