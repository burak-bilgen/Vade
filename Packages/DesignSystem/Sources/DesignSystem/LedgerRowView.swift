import SwiftUI
import Core

public struct LedgerRowView: View {
    @Environment(\.locale) private var locale
    let name: String
    let amount: Decimal
    let subtitle: String?
    let isPositive: Bool

    public init(name: String, amount: Decimal, subtitle: String? = nil, isPositive: Bool) {
        self.name = name
        self.amount = amount
        self.subtitle = subtitle
        self.isPositive = isPositive
    }

    public var body: some View {
        HStack(spacing: Spacing.m) {
            avatarView

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(name)
                    .font(Typography.font(for: .headline))
                    .foregroundStyle(ColorTokens.textPrimary)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle)
                        .font(Typography.font(for: .caption))
                        .foregroundStyle(ColorTokens.textTertiary)
                        .minimumScaleFactor(0.85)
                }
            }

            Spacer(minLength: Spacing.m)

            HStack(spacing: Spacing.xs) {
                Text(isPositive ? "\u{2191}" : "\u{2193}")
                    .font(Typography.font(for: .amount))
                    .fontWeight(.bold)
                Text(amount.formatted())
                    .font(Typography.font(for: .amount))
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.9)
            }
            .foregroundStyle(isPositive ? ColorTokens.positive : ColorTokens.negative)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
        .frame(minHeight: 44)
        .background(ColorTokens.surface)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isPositive
            ? String(localized: "accessibility.receivable", locale: locale)
            : String(localized: "accessibility.payable", locale: locale))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ColorTokens.border)
                .frame(height: 0.5)
        }
    }

    private var accessibilityLabel: String {
        let arrow = isPositive ? String(localized: "accessibility.receivable", locale: locale) : String(localized: "accessibility.payable", locale: locale)
        return "\(name), \(amount.formatted()), \(arrow)"
    }

    private var avatarView: some View {
        let initial = name.firstCharacter.uppercased()
        let stableHash = name.utf8.reduce(0) { $0 &+ Int64($1) }
        let idx = Int(abs(stableHash) % Int64(AvatarGradients.all.count))
        return ZStack {
            Circle()
                .fill(AvatarGradients.all[idx])
                .frame(width: 40, height: 40)
            Text(initial)
                .font(Typography.font(for: .headline))
                .foregroundStyle(.white)
        }
    }
}

private enum AvatarGradients {
    static let all: [LinearGradient] = [
        LinearGradient(
            colors: [Color(red: 0.40, green: 0.20, blue: 0.80), Color(red: 0.70, green: 0.30, blue: 0.90)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ),
        LinearGradient(
            colors: [Color(red: 0.10, green: 0.50, blue: 0.90), Color(red: 0.30, green: 0.80, blue: 0.70)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ),
        LinearGradient(
            colors: [Color(red: 0.90, green: 0.40, blue: 0.20), Color(red: 0.95, green: 0.60, blue: 0.30)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ),
        LinearGradient(
            colors: [Color(red: 0.80, green: 0.20, blue: 0.40), Color(red: 0.90, green: 0.40, blue: 0.60)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ),
        LinearGradient(
            colors: [Color(red: 0.20, green: 0.70, blue: 0.50), Color(red: 0.40, green: 0.90, blue: 0.70)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ),
    ]
}

#Preview {
    VStack(spacing: 0) {
        LedgerRowView(name: "Ahmet", amount: 1500, subtitle: "3 g\u{00FC}n \u{00F6}nce", isPositive: true)
        LedgerRowView(name: "Ay\u{015F}e", amount: 750, subtitle: "Vade: 15 Temmuz", isPositive: false)
        LedgerRowView(name: "Uzun isimli bir kisi", amount: 1234567, subtitle: "Cok uzun bir not yazisi", isPositive: true)
    }
    .background(ColorTokens.background)
}
