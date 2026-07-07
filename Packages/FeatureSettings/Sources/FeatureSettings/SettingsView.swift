import SwiftUI
import DesignSystem
import Core
import Domain
import Observability

// MARK: - Settings View

public struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(LanguageManager.self) private var languageManager

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    // Gradient App Header
                    gradientHeader
                        .entrance(.up, delay: 0.05)

                    // Security section
                    SuperSettingsSection(
                        title: String(localized: "settings.section.security"),
                        icon: "lock.shield.fill",
                        iconColor: ColorTokens.accent
                    ) {
                        SuperSettingsToggleRow(
                            icon: "faceid",
                            iconColor: ColorTokens.accent,
                            title: String(localized: "settings.biometric.toggle"),
                            isOn: Binding(
                                get: { viewModel.isBiometricEnabled },
                                set: { viewModel.setBiometric($0) }
                            )
                        )
                    }
                    .entrance(.up, delay: 0.1)

                    // Preferences section
                    SuperSettingsSection(
                        title: String(localized: "settings.section.preferences"),
                        icon: "slider.horizontal.3",
                        iconColor: ColorTokens.chartPurple
                    ) {
                        SuperSettingsPickerRow(
                            icon: "globe",
                            iconColor: ColorTokens.chartPurple,
                            title: String(localized: "settings.language.label"),
                            selection: Binding(
                                get: { languageManager.languageCode },
                                set: { languageManager.setLanguage($0) }
                            ),
                            options: [
                                ("tr", "Türkçe"),
                                ("en", "English"),
                                ("es", "Español"),
                                ("zh", "中文"),
                                ("hi", "हिन्दी"),
                                ("ar", "العربية"),
                            ]
                        )

                        SuperSettingsPickerRow(
                            icon: "dollarsign.circle",
                            iconColor: ColorTokens.chartPurple,
                            title: String(localized: "settings.preferredCurrency"),
                            selection: Binding(
                                get: { viewModel.preferredCurrency },
                                set: { viewModel.setCurrency($0) }
                            ),
                            options: [
                                (CurrencyKind.tryCoin, CurrencyKind.tryCoin.label),
                                (CurrencyKind.usd, CurrencyKind.usd.label),
                                (CurrencyKind.eur, CurrencyKind.eur.label),
                            ]
                        )
                    }
                    .entrance(.up, delay: 0.15)

                    // Privacy section
                    SuperSettingsSection(
                        title: String(localized: "settings.section.privacy"),
                        icon: "hand.raised.fill",
                        iconColor: ColorTokens.positive
                    ) {
                        SuperSettingsToggleRow(
                            icon: "chart.bar",
                            iconColor: ColorTokens.positive,
                            title: String(localized: "settings.analytics.toggle"),
                            isOn: Binding(
                                get: { viewModel.isAnalyticsEnabled },
                                set: { viewModel.setAnalytics($0) }
                            )
                        )
                        SuperSettingsToggleRow(
                            icon: "exclamationmark.bubble",
                            iconColor: ColorTokens.positive,
                            title: String(localized: "settings.crashlytics.toggle"),
                            isOn: Binding(
                                get: { viewModel.isCrashlyticsEnabled },
                                set: { viewModel.setCrashlytics($0) }
                            )
                        )
                    }
                    .entrance(.up, delay: 0.2)

                    // Data section
                    SuperSettingsSection(
                        title: String(localized: "settings.section.data"),
                        icon: "externaldrive.fill",
                        iconColor: ColorTokens.negative
                    ) {
                        NavigationLink {
                            DataManagementView()
                        } label: {
                            SuperSettingsNavRow(
                                icon: "trash",
                                iconColor: ColorTokens.negative,
                                title: String(localized: "settings.deleteData.button")
                            )
                        }
                    }
                    .entrance(.up, delay: 0.25)

                    // About section
                    SuperSettingsSection(
                        title: String(localized: "settings.section.about"),
                        icon: "info.circle.fill",
                        iconColor: ColorTokens.chartTeal
                    ) {
                        if let privacyURL = URL(string: "https://vade.app/privacy") {
                            Link(destination: privacyURL) {
                                SuperSettingsNavRow(
                                    icon: "doc.text",
                                    iconColor: ColorTokens.chartTeal,
                                    title: String(localized: "settings.about.privacyPolicy")
                                )
                            }
                        }
                    }
                    .entrance(.up, delay: 0.3)

                    // Version footer
                    versionFooter
                        .entrance(.fade, delay: 0.35)
                }
                .padding(.horizontal, Spacing.l)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(ColorTokens.background)
            .navigationTitle(String(localized: "settings.navigationTitle"))
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
    }

    // MARK: - Gradient Header

    private var gradientHeader: some View {
        VStack(spacing: Spacing.s) {
            // App icon placeholder
            ZStack {
                RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [ColorTokens.accent, ColorTokens.chartPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: ColorTokens.accent.opacity(0.3), radius: 12, x: 0, y: 6)

                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(String(localized: "app.name"))
                .font(Typography.font(for: .title))
                .foregroundStyle(ColorTokens.textPrimary)

            Text(String(localized: "app.subtitle"))
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(ColorTokens.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .stroke(ColorTokens.border, lineWidth: 0.5)
        )
    }

    // MARK: - Version Footer

    private var versionFooter: some View {
        VStack(spacing: Spacing.xxs) {
            Text(String(localized: "app.name"))
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textTertiary)
            Text(String(localized: "app.subtitle"))
                .font(Typography.font(for: .label))
                .foregroundStyle(ColorTokens.textTertiary.opacity(0.6))
            Text(Bundle.main.releaseVersionNumber)
                .font(Typography.font(for: .label))
                .foregroundStyle(ColorTokens.textTertiary.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }
}

// MARK: - Super Settings Section

private struct SuperSettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            // Section header with icon
            HStack(spacing: Spacing.s) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 26, height: 26)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                Text(title)
                    .font(Typography.font(for: .caption))
                    .foregroundStyle(iconColor)
                    .textCase(.uppercase)
                    .tracking(0.8)
            }
            .padding(.horizontal, Spacing.s)

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(ColorTokens.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(ColorTokens.border, lineWidth: 0.5)
            )
            .overlay(
                // Left accent bar
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(iconColor.opacity(0.4))
                    .frame(width: 3)
                    .padding(.vertical, 6),
                alignment: .leading
            )
        }
    }
}

// MARK: - Super Settings Toggle Row

private struct SuperSettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(Typography.font(for: .body))
                .foregroundStyle(ColorTokens.textPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(iconColor)
                .labelsHidden()
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }
}

// MARK: - Super Settings Picker Row

private struct SuperSettingsPickerRow<Selection: Hashable>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var selection: Selection
    let options: [(Selection, String)]

    var body: some View {
        HStack(spacing: Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(Typography.font(for: .body))
                .foregroundStyle(ColorTokens.textPrimary)

            Spacer()

            Picker("", selection: $selection) {
                ForEach(options, id: \.0) { (value, label) in
                    Text(label).tag(value)
                }
            }
            .pickerStyle(.menu)
            .tint(iconColor)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }
}

// MARK: - Super Settings Nav Row

private struct SuperSettingsNavRow: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        HStack(spacing: Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(Typography.font(for: .body))
                .foregroundStyle(ColorTokens.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
