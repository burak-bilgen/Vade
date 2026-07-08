import SwiftUI
import DesignSystem
import Core
import Domain
import Observability

// MARK: - Settings View

public struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(LanguageManager.self) private var languageManager
    private let personRepo: FetchPersonsUseCase
    private let debtRepo: FetchDebtsForPersonUseCase
    @State private var logoPulse = false

    public init(
        personRepo: FetchPersonsUseCase,
        debtRepo: FetchDebtsForPersonUseCase
    ) {
        self.personRepo = personRepo
        self.debtRepo = debtRepo
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                FinanceBackgroundAnimation()
                    .ignoresSafeArea()
                ColorTokens.background.opacity(0.12).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Gradient App Header
                        gradientHeader
                            .entrance(.up, delay: 0.05)

                        // Security section
                        SuperSettingsSection(
                            title: "settings.section.security",
                            icon: "lock.shield.fill",
                            iconColor: ColorTokens.accent
                        ) {
                            SuperSettingsToggleRow(
                                icon: "faceid",
                                iconColor: ColorTokens.accent,
                                title: "settings.biometric.toggle",
                                isOn: Binding(
                                    get: { viewModel.isBiometricEnabled },
                                    set: { viewModel.setBiometric($0) }
                                )
                            )
                        }
                        .entrance(.up, delay: 0.1)

                        // Preferences section
                        SuperSettingsSection(
                            title: "settings.section.preferences",
                            icon: "slider.horizontal.3",
                            iconColor: ColorTokens.chartPurple
                        ) {
                            SuperSettingsPickerRow(
                                icon: "globe",
                                iconColor: ColorTokens.chartPurple,
                                title: "settings.language.label",
                                selection: Binding(
                                    get: { languageManager.languageCode },
                                    set: { languageManager.setLanguage($0) }
                                ),
                                options: [
                                    ("tr", "Türkçe"),
                                    ("en", "English"),
                                    ("es", "Español"),
                                    ("zh", "简体中文"),
                                    ("hi", "हिन्दी"),
                                    ("ar", "العربية"),
                                ]
                            )

                            Divider().padding(.leading, 56)

                            SuperSettingsPickerRow(
                                icon: "dollarsign.circle",
                                iconColor: ColorTokens.chartPurple,
                                title: "settings.preferredCurrency",
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
                            title: "settings.section.privacy",
                            icon: "hand.raised.fill",
                            iconColor: ColorTokens.positive
                        ) {
                            SuperSettingsToggleRow(
                                icon: "chart.bar",
                                iconColor: ColorTokens.positive,
                                title: "settings.analytics.toggle",
                                isOn: Binding(
                                    get: { viewModel.isAnalyticsEnabled },
                                    set: { viewModel.setAnalytics($0) }
                                )
                            )
                            
                            Divider().padding(.leading, 56)
                            
                            SuperSettingsToggleRow(
                                icon: "exclamationmark.bubble",
                                iconColor: ColorTokens.positive,
                                title: "settings.crashlytics.toggle",
                                isOn: Binding(
                                    get: { viewModel.isCrashlyticsEnabled },
                                    set: { viewModel.setCrashlytics($0) }
                                )
                            )
                        }
                        .entrance(.up, delay: 0.2)

                        // Data section
                        SuperSettingsSection(
                            title: "settings.section.data",
                            icon: "externaldrive.fill",
                            iconColor: ColorTokens.negative
                        ) {
                            NavigationLink {
                                DataManagementView(
                                    personRepo: personRepo,
                                    debtRepo: debtRepo
                                )
                            } label: {
                                SuperSettingsNavRow(
                                    icon: "trash",
                                    iconColor: ColorTokens.negative,
                                    title: "settings.deleteData.button"
                                )
                            }
                        }
                        .entrance(.up, delay: 0.25)

                        // About section
                        SuperSettingsSection(
                            title: "settings.section.about",
                            icon: "info.circle.fill",
                            iconColor: ColorTokens.chartTeal
                        ) {
                            if let privacyURL = URL(string: "https://vade.app/privacy") {
                                Link(destination: privacyURL) {
                                    SuperSettingsNavRow(
                                        icon: "doc.text",
                                        iconColor: ColorTokens.chartTeal,
                                        title: "settings.about.privacyPolicy"
                                    )
                                }
                            }
                        }
                        .entrance(.up, delay: 0.3)

                        // Version footer
                        versionFooter
                            .entrance(.fade, delay: 0.35)
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.xxxl)
                }
            }
            .navigationTitle(LocalizedStringKey("settings.navigationTitle"))
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    logoPulse = true
                }
            }
        }
    }

    // MARK: - Gradient Header

    private var gradientHeader: some View {
        VStack(spacing: Spacing.s) {
            // Premium Glowing Icon Emblem (Matches onboarding)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [ColorTokens.accent.opacity(logoPulse ? 0.22 : 0.12), ColorTokens.accent.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 110, height: 110)
                    .scaleEffect(logoPulse ? 1.08 : 0.92)
                
                Circle()
                    .fill(ColorTokens.surface)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [ColorTokens.accent.opacity(0.3), ColorTokens.chartTeal.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .elevation(Elevation.level2)
                
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ColorTokens.accent, ColorTokens.chartTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: ColorTokens.accent.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .padding(.bottom, Spacing.xxs)

            Text(LocalizedStringKey("app.name"))
                .font(.custom(AppFont.jakartaBold, size: 28))
                .foregroundStyle(
                    LinearGradient(
                        colors: [ColorTokens.textPrimary, ColorTokens.accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text(LocalizedStringKey("app.subtitle"))
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(ColorTokens.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .stroke(ColorTokens.border, lineWidth: 0.5)
        )
        .elevation(Elevation.level1)
    }

    // MARK: - Version Footer

    private var versionFooter: some View {
        VStack(spacing: Spacing.xxs) {
            Text(LocalizedStringKey("app.name"))
                .font(Typography.font(for: .caption))
                .foregroundStyle(ColorTokens.textTertiary)
            Text(LocalizedStringKey("app.subtitle"))
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
    let title: LocalizedStringKey
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
                    .font(Typography.font(for: .labelEmphasis))
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
                    .padding(.vertical, Spacing.xs),
                alignment: .leading
            )
        }
    }
}

// MARK: - Super Settings Toggle Row

private struct SuperSettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: LocalizedStringKey
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
    let title: LocalizedStringKey
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
    let title: LocalizedStringKey

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
