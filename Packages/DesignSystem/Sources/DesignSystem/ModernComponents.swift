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
            .background(Color(hue: hue, saturation: 0.45, brightness: 0.75))
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
            .background(
                (isPositive ? ColorTokens.positive : ColorTokens.negative).opacity(0.1),
                in: .rect(cornerRadius: Radius.sm)
            )
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
                .font(Typography.font(for: .amount))
                .foregroundStyle(color)
            Text(label)
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textTertiary)
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

// MARK: - Premium Balance Card

public struct PremiumBalanceCard: View {
    let netAmount: Decimal
    let receivable: Decimal
    let payable: Decimal
    let personCount: Int
    let lastUpdate: Date?

    public init(netAmount: Decimal, receivable: Decimal, payable: Decimal, personCount: Int, lastUpdate: Date? = nil) {
        self.netAmount = netAmount
        self.receivable = receivable
        self.payable = payable
        self.personCount = personCount
        self.lastUpdate = lastUpdate
    }

    public var body: some View {
        VStack(spacing: 0) {
            topSection
            bottomSection
        }
        .background(
            RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous)
                .fill(balanceGradient)
                .overlay(
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.03))
                            .frame(width: 220, height: 220)
                            .offset(x: 80, y: -60)
                            .blur(radius: 30)
                        Circle()
                            .fill(.white.opacity(0.04))
                            .frame(width: 160, height: 160)
                            .offset(x: -60, y: 80)
                            .blur(radius: 30)
                    }
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 0.5)
        )
        .elevation(Elevation.level2)
    }

    private var topSection: some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                Text(String(localized: "dashboard.balance.net"))
                    .font(Typography.font(for: .label))
                    .foregroundStyle(.white.opacity(0.65))
                    .textCase(.uppercase)
                    .tracking(1.5)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(.white.opacity(0.5))
                        .frame(width: 5, height: 5)
                    Text(String(localized: "dashboard.balance.total"))
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(netAmount.formatted())
                    .font(.custom(AppFont.jakartaBold, size: 36))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(countsDown: true))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                if netAmount >= 0 {
                    Text(String(localized: "dashboard.balance.receivable.net"))
                        .font(Typography.font(for: .captionItalic))
                        .foregroundStyle(ColorTokens.positive.opacity(0.7))
                        .padding(.leading, Spacing.s)
                        .padding(.bottom, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xxl)
    }

    private var bottomSection: some View {
        HStack(spacing: 0) {
            metricItem(
                value: receivable,
                label: String(localized: "dashboard.summary.totalReceivable"),
                color: .white,
                isPositive: true
            )
            Divider()
                .frame(width: 1, height: 32)
                .overlay(.white.opacity(0.15))
            metricItem(
                value: payable,
                label: String(localized: "dashboard.summary.totalPayable"),
                color: .white.opacity(0.7),
                isPositive: false
            )
            Divider()
                .frame(width: 1, height: 32)
                .overlay(.white.opacity(0.15))
            peopleBadge
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.l)
        .background(.white.opacity(0.08))
        .clipShape(
            .rect(
                bottomLeadingRadius: Radius.xxl,
                bottomTrailingRadius: Radius.xxl
            )
        )
        .padding(.top, Spacing.l)
    }

    private func metricItem(value: Decimal, label: String, color: Color, isPositive: Bool) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(value.formatted())
                .font(Typography.font(for: .amountSmall))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(label)
                .font(Typography.font(for: .caption))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private var peopleBadge: some View {
        VStack(spacing: 2) {
            Text("\(personCount)")
                .font(Typography.font(for: .amountSmall))
                .foregroundStyle(.white)
            HStack(spacing: 3) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 8))
                Text(String(localized: "dashboard.balance.people"))
                    .font(Typography.font(for: .caption))
            }
            .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private var balanceGradient: LinearGradient {
        if netAmount.isEffectivelyZero {
            return LinearGradient(
                colors: [ColorTokens.cardBlue, ColorTokens.cardPurpleDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return netAmount > 0
            ? LinearGradient(
                colors: [ColorTokens.cardBlueDark, ColorTokens.cardBlue, ColorTokens.cardGreenDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            : LinearGradient(
                colors: [Color(red: 0.6, green: 0.12, blue: 0.12), Color(red: 0.85, green: 0.18, blue: 0.14), Color(red: 0.9, green: 0.35, blue: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.12))
                                .frame(width: 28, height: 28)
                            Image(systemName: icon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(accentColor)
                        }
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

// MARK: - Action Pill

public struct ActionPill: View {
    let icon: String
    let title: String
    let color: Color
    let action: (() -> Void)?

    public init(icon: String, title: String, color: Color, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.color = color
        self.action = action
    }

    public var body: some View {
        Group {
            if let action {
                Button(action: action) { label }
                    .premiumPress(scale: 0.92)
            } else {
                label
            }
        }
    }

    private var label: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(title)
                .font(Typography.font(for: .buttonSmall))
        }
        .foregroundStyle(color)
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.s)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(color.opacity(0.2), lineWidth: 0.5)
        )
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
            ZStack {
                Circle()
                    .fill(rank <= 3 ? rankColor.opacity(0.15) : ColorTokens.border.opacity(0.3))
                    .frame(width: 28, height: 28)
                Text("\(rank)")
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(rank <= 3 ? rankColor : ColorTokens.textTertiary)
            }

            AvatarView(name: name, size: 34)

            Text(name)
                .font(Typography.font(for: .bodyEmphasis))
                .foregroundStyle(ColorTokens.textPrimary)
                .lineLimit(1)

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(amount.formatted())
                    .font(Typography.font(for: .amountSmall))
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
        case 1: return Color(red: 0.95, green: 0.78, blue: 0.06)
        case 2: return Color(red: 0.65, green: 0.65, blue: 0.65)
        case 3: return Color(red: 0.75, green: 0.45, blue: 0.20)
        default: return ColorTokens.textTertiary
        }
    }
}

// MARK: - Metric Row

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
                    .font(Typography.font(for: .amountSmall))
                    .foregroundStyle(ColorTokens.positive)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .frame(height: 28)
                .overlay(ColorTokens.border)

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(localized: "dashboard.summary.totalPayable"))
                    .font(Typography.font(for: .label))
                    .foregroundStyle(ColorTokens.textTertiary)
                Text(payable.formatted())
                    .font(Typography.font(for: .amountSmall))
                    .foregroundStyle(ColorTokens.negative)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, Spacing.s)
    }
}

// MARK: - Mini Sparkline

public struct MiniSparkline: View {
    let data: [CGFloat]
    let lineColor: Color
    let fillColor: Color

    public init(data: [CGFloat], lineColor: Color = ColorTokens.accent, fillColor: Color = ColorTokens.accent.opacity(0.12)) {
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

                ForEach(data.indices, id: \.self) { i in
                    Circle()
                        .fill(lineColor)
                        .frame(width: 3, height: 3)
                        .position(
                            x: spacing * CGFloat(i),
                            y: h - (data[i] / maxVal) * h * 0.85
                        )
                }
            }
        }
        .frame(height: 36)
    }
}

// MARK: - Rate Tile (for dashboard strip)

public struct RateTile: View {
    let flag: String
    let code: String
    let rate: Decimal?

    public init(flag: String, code: String, rate: Decimal?) {
        self.flag = flag
        self.code = code
        self.rate = rate
    }

    public var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text(flag)
                .font(.title3)
            Text(code)
                .font(Typography.font(for: .label))
                .foregroundStyle(ColorTokens.textTertiary)
            if let rate {
                Text(rate, format: .number.precision(.fractionLength(2)))
                    .font(Typography.font(for: .amountSmall))
                    .foregroundStyle(ColorTokens.textPrimary)
                    .contentTransition(.numericText())
            } else {
                Text("--")
                    .font(Typography.font(for: .amountSmall))
                    .foregroundStyle(ColorTokens.textTertiary)
            }
        }
        .padding(.horizontal, Spacing.m)
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
}

// MARK: - Stat Card (compact metric tile)

public struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    public init(value: String, label: String, icon: String, color: Color) {
        self.value = value
        self.label = label
        self.icon = icon
        self.color = color
    }

    public var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(value)
                .font(Typography.font(for: .headline))
                .foregroundStyle(ColorTokens.textPrimary)
                .contentTransition(.numericText())
            Text(label)
                .font(Typography.font(for: .label))
                .foregroundStyle(ColorTokens.textTertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.ml)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(ColorTokens.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(ColorTokens.border, lineWidth: 0.5)
        )
    }
}

// MARK: - Dashed Divider

public struct DashedDivider: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(ColorTokens.border)
            .frame(height: 0.5)
            .frame(maxWidth: .infinity)
            .opacity(0.5)
    }
}
