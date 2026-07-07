import SwiftUI
import Core

// MARK: - Avatar View

public struct AvatarView: View {
    let name: String
    let size: CGFloat

    public init(name: String, size: CGFloat = 40) {
        self.name = name
        self.size = size
    }

    private var initials: String {
        name.components(separatedBy: .whitespaces)
            .prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }

    private var hue: Double {
        Double(name.utf8.reduce(0) { $0 + Int($1) } % 360) / 360.0
    }

    public var body: some View {
        Text(verbatim: initials)
            .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color(hue: hue, saturation: 0.5, brightness: 0.7))
            .clipShape(.circle)
    }
}

// MARK: - Balance Chip

public struct BalanceChip: View {
    let amount: Decimal
    let isPositive: Bool

    public init(amount: Decimal, isPositive: Bool) {
        self.amount = amount
        self.isPositive = isPositive
    }

    public var body: some View {
        Text(isPositive ? "+\(amount.formatted())" : "-\(amount.formatted())")
            .font(Typography.font(for: .amount))
            .foregroundStyle(isPositive ? ColorTokens.positive : ColorTokens.negative)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
            .background((isPositive ? ColorTokens.positiveLight : ColorTokens.negativeLight).opacity(0.12), in: .rect(cornerRadius: Radius.sm))
    }
}

// MARK: - Metric Tile

public struct MetricTile: View {
    let label: String
    let value: Decimal
    let color: Color

    public init(label: String, value: Decimal, color: Color) {
        self.label = label
        self.value = value
        self.color = color
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(value, format: .number.precision(.fractionLength(2)))
                .font(Typography.font(for: .amount)).foregroundStyle(color)
            Text(label)
                .font(Typography.font(for: .caption)).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.l)
        .background(ColorTokens.surface, in: .rect(cornerRadius: Radius.md))
    }
}

// MARK: - Section Header

public struct SectionHeader: View {
    let title: String
    var action: (() -> Void)?

    public init(_ title: String, action: (() -> Void)? = nil) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        HStack {
            Text(title)
                .font(Typography.font(for: .title2))
            Spacer()
            if let action {
                Button(String(localized: "common.seeAll"), action: action)
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(ColorTokens.accent)
            }
        }
    }
}

// MARK: - Premium Balance Card (Hero)

public struct PremiumBalanceCard: View {
    let netAmount: Decimal
    let receivable: Decimal
    let payable: Decimal
    let personCount: Int

    public init(netAmount: Decimal, receivable: Decimal, payable: Decimal, personCount: Int) {
        self.netAmount = netAmount
        self.receivable = receivable
        self.payable = payable
        self.personCount = personCount
    }

    public var body: some View {
        VStack(spacing: Spacing.l) {
            // Net balance
            VStack(spacing: Spacing.xxs) {
                Text(String(localized: "dashboard.balance.net"))
                    .font(Typography.font(for: .label))
                    .foregroundStyle(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(1.2)

                Text(netAmount.formatted())
                    .font(Typography.font(for: .displayMedium))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(countsDown: true))
                    .minimumScaleFactor(0.75)
            }

            // Receivable / Payable breakdown
            HStack(spacing: Spacing.xxl) {
                VStack(spacing: Spacing.xxxs) {
                    Text(String(localized: "dashboard.summary.totalReceivable"))
                        .font(Typography.font(for: .label))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(receivable.formatted())
                        .font(Typography.font(for: .amount))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                }
                Divider()
                    .frame(width: 1, height: 28)
                    .overlay(.white.opacity(0.2))
                VStack(spacing: Spacing.xxxs) {
                    Text(String(localized: "dashboard.summary.totalPayable"))
                        .font(Typography.font(for: .label))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(payable.formatted())
                        .font(Typography.font(for: .amount))
                        .foregroundStyle(.white.opacity(0.85))
                        .contentTransition(.numericText())
                }
            }

            // People count
            HStack(spacing: Spacing.xs) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 10))
                Text("\(personCount) \(String(localized: "dashboard.balance.people"))")
                    .font(Typography.font(for: .label))
            }
            .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
        .padding(.horizontal, Spacing.xl)
        .background(
            LinearGradient(
                colors: balanceColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 0.5)
        )
        .elevation(Elevation.level2)
    }

    private var balanceColors: [Color] {
        if netAmount.isEffectivelyZero {
            return [ColorTokens.accent, ColorTokens.chartPurple]
        }
        return netAmount > 0
            ? [Color(red: 0.0, green: 0.478, blue: 1.0), Color(red: 0.188, green: 0.820, blue: 0.345)]
            : [Color(red: 1.0, green: 0.271, blue: 0.227), Color(red: 1.0, green: 0.584, blue: 0.0)]
    }
}

// MARK: - Glass Card

public struct GlassCard<Content: View>: View {
    let title: String?
    let subtitle: String?
    let icon: String?
    let accentColor: Color
    let content: Content

    public init(
        title: String? = nil,
        subtitle: String? = nil,
        icon: String? = nil,
        accentColor: Color = ColorTokens.accent,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.accentColor = accentColor
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                HStack(spacing: Spacing.s) {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(accentColor)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .font(Typography.font(for: .headline))
                            .foregroundStyle(ColorTokens.textPrimary)
                        if let subtitle {
                            Text(subtitle)
                                .font(Typography.font(for: .caption))
                                .foregroundStyle(ColorTokens.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.ml)
            }

            content
                .padding(.horizontal, Spacing.l)
                .padding(.bottom, Spacing.l)
        }
        .background(ColorTokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .stroke(ColorTokens.border, lineWidth: 0.5)
        )
        .elevation(Elevation.level1)
    }
}

// MARK: - Action Pill (horizontal quick action)

public struct ActionPill: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    public init(icon: String, title: String, color: Color, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.color = color
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(Typography.font(for: .buttonSmall))
            }
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.s)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.2), lineWidth: 0.5)
            )
        }
        .premiumPress(scale: 0.92)
    }
}

// MARK: - Leaderboard Row

public struct LeaderboardRow: View {
    let rank: Int
    let name: String
    let amount: Decimal
    let isReceivable: Bool

    public init(rank: Int, name: String, amount: Decimal, isReceivable: Bool) {
        self.rank = rank
        self.name = name
        self.amount = amount
        self.isReceivable = isReceivable
    }

    public var body: some View {
        HStack(spacing: Spacing.m) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rank <= 3 ? rankColor.opacity(0.15) : ColorTokens.border.opacity(0.3))
                    .frame(width: 32, height: 32)
                Text("\(rank)")
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(rank <= 3 ? rankColor : ColorTokens.textTertiary)
            }

            AvatarView(name: name, size: 36)

            Text(name)
                .font(Typography.font(for: .bodyEmphasis))
                .foregroundStyle(ColorTokens.textPrimary)
                .lineLimit(1)

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(amount.formatted())
                    .font(Typography.font(for: .amount))
                    .foregroundStyle(isReceivable ? ColorTokens.positive : ColorTokens.negative)
                    .contentTransition(.numericText())
                HStack(spacing: 2) {
                    Image(systemName: isReceivable ? "arrow.down.left" : "arrow.up.right")
                        .font(.system(size: 8, weight: .bold))
                    Text(isReceivable
                        ? String(localized: "people.balance.receivable")
                        : String(localized: "people.balance.payable"))
                        .font(Typography.font(for: .label))
                }
                .foregroundStyle(isReceivable ? ColorTokens.positive : ColorTokens.negative)
            }
        }
        .padding(.vertical, Spacing.s)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0) // gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75) // silver
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20) // bronze
        default: return ColorTokens.textTertiary
        }
    }
}

// MARK: - Metric Row (compact receivable/payable summary)

public struct MetricRow: View {
    let receivable: Decimal
    let payable: Decimal

    public init(receivable: Decimal, payable: Decimal) {
        self.receivable = receivable
        self.payable = payable
    }

    public var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "dashboard.summary.totalReceivable"))
                    .font(Typography.font(for: .label))
                    .foregroundStyle(ColorTokens.textTertiary)
                Text(receivable.formatted())
                    .font(Typography.font(for: .amount))
                    .foregroundStyle(ColorTokens.positive)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .frame(height: 32)
                .overlay(ColorTokens.border)

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(localized: "dashboard.summary.totalPayable"))
                    .font(Typography.font(for: .label))
                    .foregroundStyle(ColorTokens.textTertiary)
                Text(payable.formatted())
                    .font(Typography.font(for: .amount))
                    .foregroundStyle(ColorTokens.negative)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, Spacing.s)
    }
}

// MARK: - Mini Sparkline (simple dot/bar chart for monthly trend)

public struct MiniSparkline: View {
    let data: [CGFloat]
    let lineColor: Color
    let fillColor: Color

    public init(data: [CGFloat], lineColor: Color = ColorTokens.accent, fillColor: Color = ColorTokens.accent.opacity(0.15)) {
        self.data = data
        self.lineColor = lineColor
        self.fillColor = fillColor
    }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let maxVal = max(data.max() ?? 1, 1)
            let spacing = data.count > 1 ? w / CGFloat(data.count - 1) : 0

            ZStack {
                // Fill
                if data.count > 1 {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: h))
                        for i in data.indices {
                            let x = CGFloat(i) * spacing
                            let y = h - (data[i] / maxVal) * h * 0.85
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        if let last = data.last {
                            let x = CGFloat(data.count - 1) * spacing
                            path.addLine(to: CGPoint(x: x, y: h))
                        }
                        path.closeSubpath()
                    }
                    .fill(fillColor)
                }

                // Line
                if data.count > 1 {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: h - (data[0] / maxVal) * h * 0.85))
                        for i in data.indices.dropFirst() {
                            let x = CGFloat(i) * spacing
                            let y = h - (data[i] / maxVal) * h * 0.85
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }

                // Dots
                ForEach(data.indices, id: \.self) { i in
                    Circle()
                        .fill(lineColor)
                        .frame(width: 4, height: 4)
                        .position(
                            x: spacing * CGFloat(i),
                            y: h - (data[i] / maxVal) * h * 0.85
                        )
                }
            }
        }
        .frame(height: 40)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            AvatarView(name: "Ahmet Yılmaz", size: 40)
            AvatarView(name: "Ayşe Demir", size: 40)
            AvatarView(name: "Mehmet Kaya", size: 40)
        }
        HStack(spacing: 12) {
            BalanceChip(amount: 1500, isPositive: true)
            BalanceChip(amount: 800, isPositive: false)
        }
        MetricTile(label: "Alacak", value: 12500, color: ColorTokens.positive)
        SectionHeader("Yaklaşan Ödemeler")
        GlassCard(title: "Aylık Trend", subtitle: "Son 6 ay", icon: "chart.line.uptrend.xyaxis", accentColor: ColorTokens.accent) {
            MiniSparkline(data: [10, 25, 15, 30, 20, 35], lineColor: ColorTokens.accent)
                .frame(height: 60)
        }
        .frame(height: 140)
        MetricRow(receivable: 15000, payable: 8500)
        LeaderboardRow(rank: 1, name: "Ahmet Yılmaz", amount: 12500, isReceivable: true)
        LeaderboardRow(rank: 2, name: "Ayşe Demir", amount: 3400, isReceivable: false)
    }
    .padding()
    .background(ColorTokens.background)
}
