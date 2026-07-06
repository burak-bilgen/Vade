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
            VStack(spacing: 0) {
                if let vm = viewModel {
                    headerSection(vm)
                    contentSection(vm)
                }
            }
        }
        .background(ColorTokens.background)
        .ignoresSafeArea(.container, edges: .top)
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

    // MARK: - Header

    private func headerSection(_ vm: DashboardViewModel) -> some View {
        VStack(spacing: 0) {
            // Top safe area spacer
            Color.clear.frame(height: 60)

            // Greeting
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeGreeting)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                    Text("Vade")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button { showAdd = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)

            // Balance card
            VStack(spacing: 4) {
                Text(String(localized: "dashboard.netBalance"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .textCase(.uppercase)

                Text(vm.netBalance, format: .number.precision(.fractionLength(2)))
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                HStack(spacing: 4) {
                    Image(systemName: vm.netBalance >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 11, weight: .bold))
                    Text(vm.netBalance >= 0
                        ? String(localized: "dashboard.youAreOwed")
                        : String(localized: "dashboard.youOwe")
                    )
                    .font(.system(size: 13))
                }
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 4)

                // Receivable / Payable pills
                HStack(spacing: 12) {
                    miniPill(icon: "arrow.down.left", value: vm.totalReceivable, color: .green)
                    miniPill(icon: "arrow.up.right", value: vm.totalPayable, color: .red)
                }
                .padding(.top, 16)
            }
            .padding(.bottom, 32)

            // Rate ticker
            if let rates = vm.exchangeRates {
                let pills: [(String, Decimal?)] = [
                    ("🇺🇸 USD", rates.usdRate),
                    ("🇪🇺 EUR", rates.eurRate),
                    ("🪙 GA", rates.goldRate),
                ].filter { $0.1 != nil }
                if !pills.isEmpty {
                    NavigationLink { RatesView() } label: {
                        HStack(spacing: 16) {
                            ForEach(pills, id: \.0) { (label, rate) in
                                HStack(spacing: 4) {
                                    Text(label)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.white.opacity(0.6))
                                    Text(rate!, format: .number.precision(.fractionLength(2)))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.1), in: .rect(cornerRadius: 12))
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
        .background(
            LinearGradient(
                colors: [ColorTokens.accent, ColorTokens.accent.opacity(0.85), ColorTokens.accent.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func miniPill(icon: String, value: Decimal, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(value, format: .number.precision(.fractionLength(2)))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.25), in: .capsule)
    }

    // MARK: - Content Section

    private func contentSection(_ vm: DashboardViewModel) -> some View {
        VStack(spacing: 16) {
            // Quick actions
            HStack(spacing: 12) {
                NavigationLink { PeopleListView() } label: {
                    quickAction(icon: "person.2.fill", color: .blue, title: String(localized: "dashboard.action.people"))
                }
                NavigationLink {
                    ChartsHostView(totalReceivable: vm.totalReceivable, totalPayable: vm.totalPayable, netBalance: vm.netBalance)
                } label: {
                    quickAction(icon: "chart.line.uptrend.xyaxis", color: .purple, title: String(localized: "dashboard.action.charts"))
                }
                NavigationLink { RatesView() } label: {
                    quickAction(icon: "dollarsign.circle.fill", color: .orange, title: String(localized: "rates.title"))
                }
            }
            .padding(.horizontal, 24)

            // Stats
            if vm.monthlyStats.totalPersonCount > 0 {
                HStack(spacing: 12) {
                    statCard(value: "\(vm.monthlyStats.totalPersonCount)", label: String(localized: "dashboard.month.people"), icon: "person.2", color: .blue)
                    statCard(value: "\(vm.monthlyStats.pendingDebtCount)", label: String(localized: "dashboard.month.pending"), icon: "clock", color: .orange)
                    statCard(value: "\(vm.monthlyStats.activePersonCount)", label: String(localized: "dashboard.month.active"), icon: "bolt", color: .green)
                }
                .padding(.horizontal, 24)
            }

            // Upcoming
            if !vm.upcomingItems.isEmpty {
                sectionCard(title: String(localized: "dashboard.upcoming.title")) {
                    ForEach(Array(vm.upcomingItems.enumerated()), id: \.element.id) { i, item in
                        upcomingRow(item)
                        if i < vm.upcomingItems.count - 1 {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            // Activity
            if !vm.recentActivity.isEmpty {
                sectionCard(title: String(localized: "dashboard.recent.title")) {
                    ForEach(Array(vm.recentActivity.enumerated()), id: \.element.id) { i, item in
                        activityRow(item)
                        if i < vm.recentActivity.count - 1 {
                            Divider().padding(.leading, 40)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            // Currency
            if !vm.currencyDistribution.isEmpty {
                sectionCard(title: String(localized: "dashboard.currency.title")) {
                    HStack(spacing: 8) {
                        ForEach(vm.currencyDistribution, id: \.kind) { item in
                            VStack(spacing: 4) {
                                Text(item.kind.rawValue)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                Text(item.total, format: .number.precision(.fractionLength(2)))
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(ColorTokens.surface, in: .rect(cornerRadius: 8))
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.vertical, 16)
        .background(ColorTokens.background)
    }

    // MARK: - Components

    private func quickAction(icon: String, color: Color, title: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.12), in: .circle)
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(ColorTokens.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(ColorTokens.surface, in: .rect(cornerRadius: 14))
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(ColorTokens.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(ColorTokens.surface, in: .rect(cornerRadius: 14))
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ColorTokens.textPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            content()
        }
        .background(ColorTokens.surface, in: .rect(cornerRadius: 14))
        .shadow(color: .black.opacity(0.03), radius: 8, y: 2)
    }

    private func upcomingRow(_ item: (id: UUID, person: Person, amount: Decimal, dueDate: Date?)) -> some View {
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
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundStyle(ColorTokens.positive)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func activityRow(_ item: ActivityItem) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(item.direction == .receivable ? .green : .red)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.personName).font(.system(size: 15, weight: .medium))
                Text(item.date, format: .relative(presentation: .named))
                    .font(.system(size: 12)).foregroundStyle(.tertiary)
            }
            Spacer()
            Text(item.direction == .receivable ? "+\(item.kind.format(item.amount))" : "-\(item.kind.format(item.amount))")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(item.direction == .receivable ? .green : .red)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return String(localized: "dashboard.greeting.morning")
        case 12..<18: return String(localized: "dashboard.greeting.afternoon")
        default: return String(localized: "dashboard.greeting.evening")
        }
    }
}

#Preview {
    NavigationStack { DashboardView() }
}
