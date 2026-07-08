import SwiftUI
import DesignSystem
import Domain
import Core
import Observability

// MARK: - Quick Add ViewModel

@MainActor
@Observable
final class QuickAddViewModel {
    var name = ""
    var amount = ""
    var kind: CurrencyKind = .tryCoin
    var direction: DebtDirection = .receivable
    var isSaving = false
    var errorMessage: String?

    private let personRepo: AddPersonUseCase
    private let debtRepo: AddDebtUseCase
    private let analytics: any AnalyticsTracking
    let onDone: () async -> Void

    init(
        personRepo: AddPersonUseCase,
        debtRepo: AddDebtUseCase,
        analytics: any AnalyticsTracking = AnalyticsService.shared,
        onDone: @escaping () async -> Void
    ) {
        self.personRepo = personRepo
        self.debtRepo = debtRepo
        self.analytics = analytics
        self.onDone = onDone
    }

    var canSave: Bool {
        !name.trimmed.isEmpty && (Decimal(string: amount) ?? .zero) > 0
    }

    func save() async -> Bool {
        guard var amt = Decimal(string: amount), amt > 0, !name.trimmed.isEmpty else { return false }
        isSaving = true
        errorMessage = nil

        do {
            let person = try await personRepo.execute(
                name: name.trimmed,
                phoneNumber: nil,
                notes: nil
            )

            var rounded = Decimal()
            NSDecimalRound(&rounded, &amt, 2, .plain)
            _ = try await debtRepo.execute(
                personID: person.id,
                amount: rounded,
                kind: kind,
                direction: direction,
                note: nil,
                dueDate: nil
            )

            analytics.track(.debtAdded(kind: kind.analyticsDebtKind))
            isSaving = false
            return true
        } catch {
            AppLog.data.error("[QuickAdd] Save failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isSaving = false
            return false
        }
    }
}

// MARK: - Quick Add Sheet

struct QuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: QuickAddViewModel?
    let personRepo: AddPersonUseCase
    let debtRepo: AddDebtUseCase
    let onDone: () async -> Void

    var body: some View {
        NavigationStack {
            if let vm = viewModel {
                quickAddForm(vm)
            }
        }
        .onAppear {
            viewModel = QuickAddViewModel(
                personRepo: personRepo,
                debtRepo: debtRepo,
                onDone: onDone
            )
        }
    }

    private func quickAddForm(_ vm: QuickAddViewModel) -> some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Amount input
                VStack(spacing: Spacing.xxs) {
                    Text(String(localized: "quickAdd.amountLabel"))
                        .font(Typography.font(for: .label))
                        .foregroundStyle(ColorTokens.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    TextField(String(localized: "debt.amount.placeholder"), text: Binding(
                        get: { vm.amount },
                        set: { vm.amount = $0 }
                    ))
                    .font(Typography.font(for: .displayMedium))
                    .foregroundStyle(ColorTokens.textPrimary)
                    .multilineTextAlignment(.center)
                    #if !os(macOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .disabled(vm.isSaving)
                }
                .padding(.top, Spacing.xl)

                // Currency picker as pill segments
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xxs) {
                        ForEach(CurrencyKind.allCases, id: \.self) { kind in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    vm.kind = kind
                                }
                            } label: {
                                Text(kind.rawValue)
                                    .font(Typography.font(for: .buttonSmall))
                                    .foregroundStyle(vm.kind == kind
                                        ? (kind.isFiat ? ColorTokens.positive : ColorTokens.chartOrange)
                                        : ColorTokens.textTertiary)
                                    .padding(.horizontal, Spacing.m)
                                    .padding(.vertical, Spacing.s)
                                    .background(
                                        Capsule().fill(vm.kind == kind
                                            ? (kind.isFiat
                                                ? ColorTokens.positiveLight.opacity(0.2)
                                                : ColorTokens.chartOrange.opacity(0.2))
                                            : ColorTokens.surface)
                                    )
                            }
                            .disabled(vm.isSaving)
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                }

                // Direction toggle pills
                HStack(spacing: Spacing.m) {
                    directionButton(.receivable, color: ColorTokens.positive, vm: vm)
                    directionButton(.payable, color: ColorTokens.negative, vm: vm)
                }
                .padding(.horizontal, Spacing.xl)

                // Person name
                VStack(spacing: Spacing.xxs) {
                    Text(String(localized: "quickAdd.personLabel"))
                        .font(Typography.font(for: .label))
                        .foregroundStyle(ColorTokens.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    TextField(String(localized: "quickAdd.personPlaceholder"), text: Binding(
                        get: { vm.name },
                        set: { vm.name = $0 }
                    ))
                    .font(Typography.font(for: .title2))
                    .foregroundStyle(ColorTokens.textPrimary)
                    .multilineTextAlignment(.center)
                    .disabled(vm.isSaving)
                }

                // Error
                if let error = vm.errorMessage {
                    Text(error)
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.negative)
                        .padding(.horizontal, Spacing.xl)
                }

                Spacer()

                // Save button
                Button {
                    Task {
                        let success = await vm.save()
                        if success {
                            HapticFeedback.notification(.success)
                            await vm.onDone()
                            dismiss()
                        }
                    }
                } label: {
                    HStack(spacing: Spacing.s) {
                        if vm.isSaving { ProgressView().tint(.white) }
                        Text(String(localized: "quickAdd.save"))
                            .font(Typography.font(for: .button))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: Spacing.massive)
                    .background(
                        Capsule().fill(vm.canSave ? ColorTokens.accent : ColorTokens.border)
                    )
                    .foregroundStyle(vm.canSave && !vm.isSaving ? .white : ColorTokens.textTertiary)
                }
                .disabled(!vm.canSave || vm.isSaving)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxxl)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(ColorTokens.background)
        .navigationTitle(String(localized: "quickAdd.title"))
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "quickAdd.cancel")) { dismiss() }
                    .disabled(vm.isSaving)
            }
        }
    }

    private func directionButton(_ direction: DebtDirection, color: Color, vm: QuickAddViewModel) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { vm.direction = direction }
        } label: {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: direction == .receivable ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                Text(direction == .receivable
                    ? String(localized: "quickAdd.receivable")
                    : String(localized: "quickAdd.payable"))
                    .font(Typography.font(for: .buttonSmall))
            }
            .foregroundStyle(vm.direction == direction ? color : ColorTokens.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.m)
            .background(
                Capsule().fill(vm.direction == direction
                    ? color.opacity(0.15) : ColorTokens.surface)
            )
        }
        .disabled(vm.isSaving)
    }
}

// MARK: - Helpers

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
