import SwiftUI
import Core

public struct LedgerRowView: View {
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
                    .foregroundColor(Color("ink900"))
                if let subtitle {
                    Text(subtitle)
                        .font(Typography.font(for: .caption))
                        .foregroundColor(Color("ink400"))
                }
            }
            Spacer()
            HStack(spacing: Spacing.xs) {
                Image(systemName: isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundColor(isPositive
                        ? Color("positive600")
                        : Color("negative600"))
                Text(amount.formatted())
                    .font(Typography.font(for: .amount))
                    .foregroundColor(isPositive
                        ? Color("positive600")
                        : Color("negative600"))
            }
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
        .background(Color("surface"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(amount.formatted())")
        .accessibilityHint(isPositive
            ? String(localized: "accessibility.receivable")
            : String(localized: "accessibility.payable"))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color("ledgerLine"))
                .frame(height: 1)
                .padding(.leading, Spacing.xxxl + Spacing.l)
        }
    }

    private var avatarView: some View {
        let initial = name.firstCharacter.uppercased()
        let idx = abs(name.hashValue) % AvatarColors.colors.count
        return ZStack {
            Circle().fill(AvatarColors.colors[idx]).frame(width: 36, height: 36)
            Text(initial).font(Typography.font(for: .headline)).foregroundColor(.white)
        }
    }
}

private enum AvatarColors {
    static let colors: [Color] = [
        Color("ink900"),
        Color("brass700"),
        Color("positive600"),
        Color("negative600"),
        Color("ink700"),
    ]
}

#Preview {
    VStack(spacing: 0) {
        LedgerRowView(name: "Ahmet", amount: 1500, subtitle: "3 gün önce", isPositive: true)
        LedgerRowView(name: "Ayşe", amount: 750, subtitle: "Vade: 15 Temmuz", isPositive: false)
    }
    .background(Color("background"))
}
