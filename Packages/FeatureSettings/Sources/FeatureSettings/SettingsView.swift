import SwiftUI
import DesignSystem
import Core
import Domain
import Observability

// MARK: - Settings View

public struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    // Profile header
                    VStack(spacing: Spacing.xs) {
                        ZStack {
                            Circle()
                                .fill(ColorTokens.accent.opacity(0.1))
                                .frame(width: 72, height: 72)
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(ColorTokens.accent)
                        }
                        Text("Vade")
                            .font(Typography.font(for: .title2))
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text(Bundle.main.releaseVersionNumber)
                            .font(Typography.font(for: .caption))
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                    .padding(.vertical, Spacing.xl)

                    // Security section
                    SettingsSection(title: String(localized: "settings.section.security")) {
                        SettingsToggleRow(
                            icon: "faceid",
                            iconColor: ColorTokens.chartBlue,
                            title: String(localized: "settings.biometric.toggle"),
                            isOn: Binding(
                                get: { viewModel.isBiometricEnabled },
                                set: { viewModel.setBiometric($0) }
                            )
                        )
                    }

                    // Preferences
                    SettingsSection(title: String(localized: "settings.section.preferences")) {
                        SettingsPickerRow(
                            icon: "globe",
                            iconColor: ColorTokens.chartTeal,
                            title: String(localized: "settings.language.label"),
                            selection: Binding(
                                get: { viewModel.selectedLanguage },
                                set: { viewModel.setLanguage($0) }
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

                        SettingsPickerRow(
                            icon: "dollarsign.circle",
                            iconColor: ColorTokens.chartOrange,
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

                    // Privacy
                    SettingsSection(title: String(localized: "settings.section.privacy")) {
                        SettingsToggleRow(
                            icon: "chart.bar",
                            iconColor: ColorTokens.chartPurple,
                            title: String(localized: "settings.analytics.toggle"),
                            isOn: Binding(
                                get: { viewModel.isAnalyticsEnabled },
                                set: { viewModel.setAnalytics($0) }
                            )
                        )
                        SettingsToggleRow(
                            icon: "exclamationmark.bubble",
                            iconColor: ColorTokens.chartOrange,
                            title: String(localized: "settings.crashlytics.toggle"),
                            isOn: Binding(
                                get: { viewModel.isCrashlyticsEnabled },
                                set: { viewModel.setCrashlytics($0) }
                            )
                        )
                    }

                    // Data
                    SettingsSection(title: String(localized: "settings.section.data")) {
                        NavigationLink {
                            DataManagementView()
                        } label: {
                            SettingsNavRow(
                                icon: "trash",
                                iconColor: ColorTokens.negative,
                                title: String(localized: "settings.deleteData.button")
                            )
                        }
                    }

                    // About
                    SettingsSection(title: String(localized: "settings.section.about")) {
                        HStack {
                            Text(String(localized: "settings.about.version"))
                                .font(Typography.font(for: .body))
                                .foregroundStyle(ColorTokens.textPrimary)
                            Spacer()
                            Text(Bundle.main.releaseVersionNumber)
                                .font(Typography.font(for: .amountSmall))
                                .foregroundStyle(ColorTokens.textTertiary)
                        }
                        .padding(.horizontal, Spacing.l)
                        .padding(.vertical, Spacing.m)

                        if let privacyURL = URL(string: "https://vade.app/privacy") {
                            Link(destination: privacyURL) {
                                SettingsNavRow(
                                    icon: "doc.text",
                                    iconColor: ColorTokens.chartBlue,
                                    title: String(localized: "settings.about.privacyPolicy")
                                )
                            }
                        }
                    }

                    Spacer().frame(height: Spacing.xxxl)
                }
                .padding(.horizontal, Spacing.l)
            }
            .background(ColorTokens.background)
            .navigationTitle(String(localized: "settings.navigationTitle"))
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Settings Section

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textTertiary)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.horizontal, Spacing.s)
                .padding(.bottom, Spacing.xxs)

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(ColorTokens.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(ColorTokens.border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Settings Toggle Row

private struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(Typography.font(for: .body))
                .foregroundStyle(ColorTokens.textPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(ColorTokens.accent)
                .labelsHidden()
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }
}

// MARK: - Settings Picker Row

private struct SettingsPickerRow<Selection: Hashable>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var selection: Selection
    let options: [(Selection, String)]

    var body: some View {
        HStack(spacing: Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
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
            .tint(ColorTokens.accent)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }
}

// MARK: - Settings Nav Row

private struct SettingsNavRow: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        HStack(spacing: Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
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
