import SwiftUI
import SwiftData
import DesignSystem
import Domain
import Data

// MARK: - Dashboard

public struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardViewModel?
    @State private var showAdd = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let vm = viewModel {
                    greetingHeader
                    balanceHero(vm)
                    quickActions(vm)
                    if !vm.currencyDistribution.isEmpty { currencyStrip(vm) }
                    rateStrip(vm)
                    if !vm.recentActivity.isEmpty { activityTimeline(vm) }
                    if !vm.upcomingItems.isEmpty { upcomingCards(vm) }
                }
            }
            .padding(.bottom, 48)
        }
        .background(ColorTokens.background)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAdd) {
            QuickAddSheet { await viewModel?.loadData() }
        }
        .task {
            let vm = DashboardViewModel(modelContext: modelContext)
            viewModel = vm
            await vm.loadData()
        }
        .refreshable { await viewModel?.loadData() }
    }

    // MARK: Greeting

    private var greetingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeGreeting)
                    .font(.system(size: 28, weight: .bold))
                if let vm = viewModel {
                    Text("\(vm.persons.count) \(String(localized: "people")) · \(vm.monthlyStats.pendingDebtCount) \(String(localized: "pending"))")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return String(localized: "dashboard.greeting.morning")
        case 12..<18: return String(localized: "dashboard.greeting.afternoon")
        default: return String(localized: "dashboard.greeting.evening")
        }
    }

    // MARK: Balance Hero

    private func balanceHero(_ vm: DashboardViewModel) -> some View {
        VStack(spacing: 8) {
            Text(String(localized: "dashboard.netBalance"))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1.5)

            Text(vm.netBalance, format: .number.precision(.fractionLength(2)))
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(balanceColor(vm.netBalance))
                .contentTransition(.numericText())

            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text(vm.totalReceivable, format: .number.precision(.fractionLength(2)))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(ColorTokens.positive)
                    Text(String(localized: "dashboard.receivable"))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                VStack(spacing: 2) {
                    Text(vm.totalPayable, format: .number.precision(.fractionLength(2)))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(ColorTokens.negative)
                    Text(String(localized: "dashboard.payable"))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(ColorTokens.surface, in: .rect(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    // MARK: Quick Actions

    private func quickActions(_ vm: DashboardViewModel) -> some View {
        HStack(spacing: 12) {
            NavigationLink { PeopleListView() } label: {
                VStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(ColorTokens.accent)
                        .frame(width: 48, height: 48)
                        .background(ColorTokens.accent.opacity(0.1), in: .circle)
                    Text(String(localized: "dashboard.action.people"))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(ColorTokens.surface, in: .rect(cornerRadius: 12))
            }

            NavigationLink {
                ChartsHostView(totalReceivable: vm.totalReceivable, totalPayable: vm.totalPayable, netBalance: vm.netBalance)
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 20))
                        .foregroundStyle(ColorTokens.accent)
                        .frame(width: 48, height: 48)
                        .background(ColorTokens.accent.opacity(0.1), in: .circle)
                    Text(String(localized: "dashboard.action.charts"))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(ColorTokens.surface, in: .rect(cornerRadius: 12))
            }

            Button {
                showAdd = true
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(ColorTokens.accent, in: .circle)
                    Text(String(localized: "dashboard.action.newDebt"))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(ColorTokens.surface, in: .rect(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: Currency Strip

    private func currencyStrip(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "dashboard.currency.title"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1.5)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.currencyDistribution, id: \.kind) { item in
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.kind.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                                Text(item.total, format: .number.precision(.fractionLength(2)))
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(ColorTokens.accent)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(ColorTokens.surface, in: .rect(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: Rate Strip

    @ViewBuilder
    private func rateStrip(_ vm: DashboardViewModel) -> some View {
        if let rates = vm.exchangeRates {
            let pills: [(String, String, Decimal?)] = [
                ("🇺🇸", "USD", rates.usdRate),
                ("🇪🇺", "EUR", rates.eurRate),
                ("🪙", "GA", rates.goldRate),
            ].filter { $0.2 != nil }
            if !pills.isEmpty {
                NavigationLink { RatesView() } label: {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(pills, id: \.1) { (flag, code, rate) in
                                ratePill(flag: flag, code: code, rate: rate!)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    private func ratePill(flag: String, code: String, rate: Decimal?) -> some View {
        HStack(spacing: 4) {
            Text(flag)
            Text(code).font(.system(size: 11)).foregroundStyle(.secondary)
            if let rate {
                Text(rate, format: .number.precision(.fractionLength(2)))
                    .font(.system(size: 13, weight: .medium))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(ColorTokens.surface, in: .capsule)
    }

    // MARK: Activity Timeline

    private func activityTimeline(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "dashboard.recent.title"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1.5)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(Array(vm.recentActivity.enumerated()), id: \.element.id) { i, item in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(item.direction == .receivable ? ColorTokens.positive : ColorTokens.negative)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.personName)
                                .font(.system(size: 15, weight: .medium))
                            Text(item.date, format: .relative(presentation: .named))
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Text(item.direction == .receivable ? "+\(item.kind.format(item.amount))" : "-\(item.kind.format(item.amount))")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(item.direction == .receivable ? ColorTokens.positive : ColorTokens.negative)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    if i < vm.recentActivity.count - 1 {
                        Divider().padding(.leading, 40)
                    }
                }
            }
            .background(ColorTokens.surface, in: .rect(cornerRadius: 12))
            .padding(.horizontal, 20)
        }
    }

    // MARK: Upcoming

    private func upcomingCards(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "dashboard.upcoming.title"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1.5)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(Array(vm.upcomingItems.enumerated()), id: \.element.id) { i, item in
                    HStack(spacing: 12) {
                        AvatarView(name: item.person.name, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.person.name).font(.system(size: 15, weight: .medium))
                            if let due = item.dueDate {
                                Text(due, format: .dateTime.day().month(.abbreviated))
                                    .font(.system(size: 12)).foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                        Text(item.amount, format: .number.precision(.fractionLength(2)))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(ColorTokens.positive)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    if i < vm.upcomingItems.count - 1 {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(ColorTokens.surface, in: .rect(cornerRadius: 12))
            .padding(.horizontal, 20)
        }
    }

    // MARK: Helpers

    private func balanceColor(_ balance: Decimal) -> Color {
        if balance.isEffectivelyZero { return .primary }
        return balance > 0 ? ColorTokens.positive : ColorTokens.negative
    }
}

// MARK: - Quick Add Sheet

private struct QuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var amount = ""
    @State private var kind: CurrencyKind = .tryCoin
    @State private var direction: DebtDirection = .receivable
    let onDone: () async -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "quickAdd.person"), text: $name)
                    TextField(String(localized: "quickAdd.amount"), text: $amount)
                        .keyboardType(.decimalPad)
                }
                Section {
                    Picker(String(localized: "quickAdd.type"), selection: $kind) {
                        ForEach(CurrencyKind.allCases, id: \.self) { k in
                            Text(k.rawValue).tag(k)
                        }
                    }
                    Picker(String(localized: "quickAdd.direction"), selection: $direction) {
                        Text(String(localized: "quickAdd.receivable")).tag(DebtDirection.receivable)
                        Text(String(localized: "quickAdd.payable")).tag(DebtDirection.payable)
                    }
                }
            }
            .navigationTitle(String(localized: "quickAdd.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "quickAdd.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "quickAdd.save")) {
                        guard !name.isEmpty, let amt = Decimal(string: amount), amt > 0 else { return }
                        let person = Person(name: name)
                        let model = PersonModel(name: person.name, phoneNumber: person.phoneNumber, notes: person.notes)
                        modelContext.insert(model)
                        let debt = DebtRecordModel(personID: model.id, amount: amt,
                                                     kindRawValue: kind.rawValue,
                                                     directionRawValue: direction == .receivable ? "receivable" : "payable")
                        modelContext.insert(debt)
                        try? modelContext.save()
                        dismiss()
                        Task { await onDone() }
                    }
                    .disabled(name.isEmpty || (Decimal(string: amount) ?? .zero) <= .zero)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { DashboardView() }
}
