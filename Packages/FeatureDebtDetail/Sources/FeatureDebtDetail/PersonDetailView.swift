import SwiftUI
import DesignSystem
import Domain
import Observability

// MARK: - Person Detail View

public struct PersonDetailView: View {
    @Environment(\.locale) private var locale
    let person: Person
    @State private var viewModel: PersonDetailViewModel?
    @State private var showAddDebt = false
    @State private var selectedDebt: DebtRecord?
    private let analytics: any AnalyticsTracking = AnalyticsService.shared

    private let personRepo: AddPersonUseCase & FetchPersonsUseCase
    private let debtRepo: FetchDebtsForPersonUseCase & AddDebtUseCase
    private let balanceRepo: CalculateBalanceUseCase
    private let paymentRepo: RecordPaymentUseCase & FetchPaymentsForDebtUseCase

    public init(
        person: Person,
        personRepo: AddPersonUseCase & FetchPersonsUseCase,
        debtRepo: FetchDebtsForPersonUseCase & AddDebtUseCase,
        balanceRepo: CalculateBalanceUseCase,
        paymentRepo: RecordPaymentUseCase & FetchPaymentsForDebtUseCase
    ) {
        self.person = person
        self.personRepo = personRepo
        self.debtRepo = debtRepo
        self.balanceRepo = balanceRepo
        self.paymentRepo = paymentRepo
    }

    @State private var contentAppeared = false

    public var body: some View {
        ZStack {
            FinanceBackgroundAnimation()
                .ignoresSafeArea()
            ColorTokens.background.opacity(0.12).ignoresSafeArea()

            Group {
                if let vm = viewModel {
                    contentView(vm)
                } else {
                    PersonDetailSkeleton()
                        .entrance(.fade)
                        .task {
                            let vm = PersonDetailViewModel(
                                person: person,
                                debtRepo: debtRepo,
                                balanceRepo: balanceRepo,
                                paymentRepo: paymentRepo,
                                analytics: analytics
                            )
                            viewModel = vm
                            await vm.loadData()
                            withAnimation(.spring(response: 0.5)) {
                                contentAppeared = true
                            }
                        }
                }
            }
        }
        .background(ColorTokens.background)
        .navigationTitle(person.name)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("personDetail.addDebt.button", systemImage: "plus") {
                    showAddDebt = true
                }
                .premiumPress()
                .symbolEffect(.bounce.up, value: viewModel?.debts.count ?? 0)
            }
        }
        .sheet(isPresented: $showAddDebt) {
            AddDebtSheet(person: person, analytics: analytics) { amount, kind, direction, note, dueDate in
                await viewModel?.addDebt(amount: amount, kind: kind, direction: direction, note: note, dueDate: dueDate)
                HapticFeedback.notification(.success)
                showAddDebt = false
            }
        }
        .sheet(item: $selectedDebt) { debt in
            RecordPaymentSheet(debt: debt) { amount, note in
                await viewModel?.recordPayment(debtRecordID: debt.id, amount: amount, note: note)
                HapticFeedback.notification(.success)
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
                // ✦ Balance header - Glassmorphism card
                VStack(spacing: Spacing.xs) {
                    Text("personDetail.balance.label")
                        .font(Typography.font(for: .label))
                        .foregroundStyle(ColorTokens.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    Text(formattedBalance(amount: vm.balance, currency: vm.displayCurrency))
                        .font(Typography.font(for: .displayMedium))
                        .foregroundStyle(balanceColor(vm.balance))
                        .contentTransition(.numericText(countsDown: true))
                        .minimumScaleFactor(0.85)
                        .scaleEffect(contentAppeared ? 1 : 0.7)
                        .opacity(contentAppeared ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1), value: contentAppeared)

                    // Direction indicator
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: vm.balance >= 0 ? "arrow.up.forward" : "arrow.down.forward")
                            .font(.system(size: 10, weight: .bold))
                        Group {
                            if vm.balance >= 0 {
                                Text("personDetail.balance.receivable")
                            } else {
                                Text("personDetail.balance.payable")
                            }
                        }
                            .font(Typography.font(for: .caption))
                    }
                    .foregroundStyle(balanceColor(vm.balance))
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.xxs)
                    .background(balanceColor(vm.balance).opacity(0.12), in: .capsule)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.xxl)
                .background(ColorTokens.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                        .stroke(ColorTokens.border, lineWidth: 0.5)
                )

                // Quick actions (call, message, share)
                if let phone = person.phoneNumber, !phone.isEmpty {
                    HStack(spacing: Spacing.m) {
                        quickActionButton(
                            icon: "phone.fill",
                            label: "personDetail.action.call",
                            color: ColorTokens.positive
                        ) {
                            guard let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") else { return }
                            UIApplication.shared.open(url)
                            HapticFeedback.impact(.light)
                        }

                        quickActionButton(
                            icon: "message.fill",
                            label: "personDetail.action.message",
                            color: ColorTokens.chartBlue
                        ) {
                            guard let url = URL(string: "sms://\(phone.replacingOccurrences(of: " ", with: ""))") else { return }
                            UIApplication.shared.open(url)
                            HapticFeedback.impact(.light)
                        }

                        quickActionButton(
                            icon: "square.and.arrow.up",
                            label: "personDetail.action.share",
                            color: ColorTokens.accent
                        ) {
                            shareBalance(vm: vm)
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .entrance(.up, delay: 0.15)
                }

                // Debt count summary - staggered entrance
                HStack(spacing: Spacing.m) {
                    DebtSummaryChip(
                        count: vm.debts.filter { $0.status == .pending }.count,
                        label: "personDetail.status.pending",
                        color: ColorTokens.chartOrange
                    )
                    .entrance(.scale, delay: 0.2)
                    DebtSummaryChip(
                        count: vm.debts.filter { $0.status == .paid }.count,
                        label: "personDetail.status.paid",
                        color: ColorTokens.positive
                    )
                    .entrance(.scale, delay: 0.25)
                    DebtSummaryChip(
                        count: vm.debts.filter { $0.status == .archived }.count,
                        label: "personDetail.status.archived",
                        color: ColorTokens.textTertiary
                    )
                    .entrance(.scale, delay: 0.3)
                }
                .padding(.horizontal, Spacing.xl)

                // Timeline header
                HStack {
                    Text("personDetail.history.title")
                        .font(Typography.font(for: .title2))
                        .foregroundStyle(ColorTokens.textPrimary)
                    Spacer()
                    Text("\(vm.debts.count)")
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textTertiary)
                        .padding(.horizontal, Spacing.s)
                        .padding(.vertical, Spacing.xxs)
                        .background(Capsule().fill(ColorTokens.surface))
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, Spacing.xl)
                .entrance(.up, delay: 0.3)

                // Timeline - staggered entrance
                if vm.debts.isEmpty {
                    EmptyStateView(
                        title: "personDetail.empty.title",
                        subtitle: "personDetail.empty.subtitle"
                    )
                    .padding(.top, Spacing.xxxl)
                    .entrance(.fade)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(vm.debts.enumerated()), id: \.element.id) { i, debt in
                            TimelineDebtRow(
                                debt: debt,
                                isLast: i == vm.debts.count - 1,
                                onTap: {
                                    HapticFeedback.impact(.light)
                                    if debt.status == .pending { selectedDebt = debt }
                                }
                            )
                            .entrance(.leading, delay: Double(i) * 0.07, duration: 0.4)
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

    // MARK: - Quick Actions

    private func quickActionButton(icon: String, label: LocalizedStringKey, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(color.opacity(0.12)))
                Text(label)
                    .font(Typography.font(for: .label))
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(ColorTokens.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(ColorTokens.border, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func shareBalance(vm: PersonDetailViewModel) {
        let text = "\(person.name) - \(vm.balance.formatted())"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              let root = window.rootViewController else { return }
        root.present(av, animated: true)
        HapticFeedback.impact(.light)
    }

    private func formattedBalance(amount: Decimal, currency: CurrencyKind) -> String {
        let isNegative = amount < 0
        let absFormatted = currency.format(amount.magnitude, locale: locale)
        return isNegative ? "-\(absFormatted)" : absFormatted
    }
}

// MARK: - Debt Summary Chip

private struct DebtSummaryChip: View {
    let count: Int
    let label: LocalizedStringKey
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
                        Text(debt.note ?? debt.kind.displayName)
                            .font(Typography.font(for: .bodyEmphasis))
                            .foregroundStyle(ColorTokens.textPrimary)
                            .lineLimit(2)
                        Spacer()
                        Text(debt.kind.format(debt.amount))
                            .font(Typography.font(for: .amount))
                            .foregroundStyle(debt.direction == .receivable
                                ? ColorTokens.positive : ColorTokens.negative)
                            .contentTransition(.numericText())
                    }

                    // Meta row
                    HStack(spacing: Spacing.s) {
                        Label(debt.kind.displayName, systemImage: debt.kind.isFiat ? "dollarsign" : "star")
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
                            .padding(.vertical, Spacing.xxxs)
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
        .accessibilityAddTraits(debt.status == .pending ? .isButton : [])
        .accessibilityLabel(
            debt.status == .pending
                ? "\(debt.kind.format(debt.amount)), \(statusLabel(debt.status))"
                : ""
        )
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

    var parsedAmount: Decimal? { Decimal(string: amountText, locale: .current) }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                // Amount input - premium style
                VStack(spacing: Spacing.xxs) {
                    Text("debt.add.amountPlaceholder")
                        .font(Typography.font(for: .label))
                        .foregroundStyle(ColorTokens.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    TextField("debt.amount.placeholder", text: $amountText)
                        .font(Typography.font(for: .displayMedium))
                        .foregroundStyle(ColorTokens.textPrimary)
                        .multilineTextAlignment(.center)
                        #if !os(macOS)
                        .keyboardType(.decimalPad)
                        #endif
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
                                Text(kind.displayName)
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
                    TextField("debt.add.notePlaceholder", text: $note)
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
                    Label("debt.add.dueDateToggle", systemImage: "calendar")
                        .font(Typography.font(for: .body))
                }
                .tint(ColorTokens.accent)
                .disabled(isSaving)
                .padding(.horizontal, Spacing.xl)

                if hasDueDate {
                    DatePicker(
                        "debt.add.dueDatePicker",
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
                        if isSaving { ProgressView().tint(.white) }
                        Text("debt.add.save")
                            .font(Typography.font(for: .button))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: Spacing.massive)
                    .background(
                        Capsule().fill(canSave ? ColorTokens.accent : ColorTokens.border)
                    )
                    .foregroundStyle(canSave && !isSaving ? .white : ColorTokens.textTertiary)
                }
                .disabled(!canSave || isSaving)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(ColorTokens.background)
            .navigationTitle(LocalizedStringKey("debt.add.title"))
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("debt.add.cancel") { dismiss() }
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
                Text(direction == .receivable                    ? "debt.add.direction.receivable" : "debt.add.direction.payable")
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

    var parsedAmount: Decimal? { Decimal(string: amountText, locale: .current) }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.xxs) {
                    Text("payment.remainingBalance")
                        .font(Typography.font(for: .label))
                        .foregroundStyle(ColorTokens.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Text(debt.kind.format(debt.remainingBalance))
                        .font(Typography.font(for: .displayMedium))
                        .foregroundStyle(debt.direction == .receivable
                            ? ColorTokens.positive : ColorTokens.negative)
                        .contentTransition(.numericText())
                }
                .padding(.top, Spacing.xxl)

                // Amount input
                VStack(spacing: Spacing.xxs) {
                    Text("payment.amountPlaceholder")
                        .font(Typography.font(for: .label))
                        .foregroundStyle(ColorTokens.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    TextField("debt.amount.placeholder", text: $amountText)
                        .font(Typography.font(for: .displayMedium))
                        .foregroundStyle(ColorTokens.textPrimary)
                        .multilineTextAlignment(.center)
                        #if !os(macOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .disabled(isSaving)
                }

                // Note
                HStack(spacing: Spacing.m) {
                    Image(systemName: "note.text")
                        .foregroundStyle(ColorTokens.textTertiary)
                    TextField("payment.notePlaceholder", text: $note)
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
                    quickFillButton(amount: debt.remainingBalance, label: "payment.full")
                    quickFillButton(amount: debt.remainingBalance / 2, label: "payment.half")
                    quickFillButton(amount: debt.remainingBalance / 4, label: "payment.quarter")
                }
                .padding(.horizontal, Spacing.xl)

                // Save
                Button {
                    Task { await save() }
                } label: {
                    HStack(spacing: Spacing.s) {
                        if isSaving { ProgressView().tint(.white) }
                        Text("payment.save")
                            .font(Typography.font(for: .button))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: Spacing.massive)
                    .background(
                        Capsule().fill(canSave ? ColorTokens.accent : ColorTokens.border)
                    )
                    .foregroundStyle(canSave && !isSaving ? .white : ColorTokens.textTertiary)
                }
                .disabled(!canSave || isSaving)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(ColorTokens.background)
            .navigationTitle(LocalizedStringKey("payment.title"))
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("payment.cancel") { dismiss() }
                        .disabled(isSaving)
                }
            }
        }
    }

    private var canSave: Bool { (parsedAmount ?? .zero) > 0 }

    private func quickFillButton(amount: Decimal, label: LocalizedStringKey) -> some View {
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

    private func save() async {
        guard let amount = parsedAmount, amount > 0 else { return }
        isSaving = true
        await onSave(amount, note.trimmed.isEmpty ? nil : note.trimmed)
        isSaving = false
    }
}

// MARK: - Helpers

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

// MARK: - Loading Skeleton

private struct PersonDetailSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.l) {
                // Balance skeleton
                SkeletonCard(lines: 2)
                    .frame(height: 120)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.l)

                // Quick actions skeleton
                HStack(spacing: Spacing.m) {
                    ForEach(0..<3, id: \.self) { _ in
                        ShimmerView(cornerRadius: Radius.md)
                            .frame(height: 72)
                    }
                }
                .padding(.horizontal, Spacing.xl)

                // Chips skeleton
                HStack(spacing: Spacing.m) {
                    ForEach(0..<3, id: \.self) { _ in
                        ShimmerView(cornerRadius: Radius.md)
                            .frame(height: 64)
                    }
                }
                .padding(.horizontal, Spacing.xl)

                // Timeline items skeleton
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonCard(lines: 2)
                        .padding(.horizontal, Spacing.xl)
                }
            }
            .padding(.vertical, Spacing.l)
        }
    }
}

// Preview disabled: requires repository injection.
