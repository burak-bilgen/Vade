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
                    .foregroundColor(Color("ink900", bundle: .module))
                if let subtitle {
                    Text(subtitle)
                        .font(Typography.font(for: .caption))
                        .foregroundColor(Color("ink400", bundle: .module))
                }
            }
            Spacer()
            HStack(spacing: Spacing.xs) {
                Image(systemName: isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundColor(isPositive
                        ? Color("positive600", bundle: .module)
                        : Color("negative600", bundle: .module))
                Text(amount.formatted())
                    .font(Typography.font(for: .amount))
                    .foregroundColor(isPositive
                        ? Color("positive600", bundle: .module)
                        : Color("negative600", bundle: .module))
            }
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
        .background(Color("surface", bundle: .module))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(amount.formatted())")
        .accessibilityHint(isPositive
            ? String(localized: "accessibility.receivable")
            : String(localized: "accessibility.payable"))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color("ledgerLine", bundle: .module))
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
        Color("ink900", bundle: .module),
        Color("brass700", bundle: .module),
        Color("positive600", bundle: .module),
        Color("negative600", bundle: .module),
        Color("ink700", bundle: .module),
    ]
}

#Preview {
    VStack(spacing: 0) {
        LedgerRowView(name: "Ahmet", amount: 1500, subtitle: "3 gün önce", isPositive: true)
        LedgerRowView(name: "Ayşe", amount: 750, subtitle: "Vade: 15 Temmuz", isPositive: false)
    }
    .background(Color("background", bundle: .module))
}
