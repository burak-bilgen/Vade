import SwiftUI
import DesignSystem
import Core

public struct LanguageSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LanguageManager.self) private var languageManager
    
    private let languages = [
        ("tr", "Türkçe", "🇹🇷"),
        ("en", "English", "🇬🇧"),
        ("es", "Español", "🇪🇸"),
        ("zh", "中文", "🇨🇳"),
        ("hi", "हिन्दी", "🇮🇳"),
        ("ar", "العربية", "🇦🇪")
    ]
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: Spacing.l) {
            // Sheet Header
            HStack {
                Text(String(localized: "settings.language.label"))
                    .font(Typography.font(for: .title3))
                    .foregroundStyle(ColorTokens.textPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(ColorTokens.textTertiary)
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.top, Spacing.l)
            
            // Language choices grid/list
            ScrollView {
                VStack(spacing: Spacing.s) {
                    ForEach(languages, id: \.0) { code, name, flag in
                        let isSelected = languageManager.languageCode == code
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                languageManager.setLanguage(code)
                            }
                            HapticFeedback.selection()
                            dismiss()
                        } label: {
                            HStack(spacing: Spacing.m) {
                                Text(flag)
                                    .font(.system(size: 24))
                                Text(name)
                                    .font(Typography.font(for: .bodyEmphasis))
                                    .foregroundStyle(ColorTokens.textPrimary)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(ColorTokens.accent)
                                } else {
                                    Circle()
                                        .stroke(ColorTokens.border, lineWidth: 1.5)
                                        .frame(width: 20, height: 20)
                                }
                            }
                            .padding(.horizontal, Spacing.l)
                            .padding(.vertical, Spacing.m)
                            .background(
                                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                    .fill(isSelected ? ColorTokens.accent.opacity(0.06) : ColorTokens.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                    .stroke(isSelected ? ColorTokens.accent.opacity(0.3) : ColorTokens.border, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, Spacing.l)
            }
        }
        .padding(.bottom, Spacing.xl)
        .background(ColorTokens.background)
    }
}
