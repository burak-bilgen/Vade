import SwiftUI
import DesignSystem
import Core
import Foundation
import Domain
import Observability

// MARK: - Settings View

public struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                // Security
                Section {
                    Toggle(isOn: Binding(
                        get: { viewModel.isBiometricEnabled },
                        set: { viewModel.setBiometric($0) }
                    )) {
                        Label(
                            String(localized: "settings.biometric.toggle"),
                            systemImage: "faceid"
                        )
                    }
                } header: {
                    Text(String(localized: "settings.section.security"))
                }

                // Preferences
                Section {
                    Picker(selection: Binding(
                        get: { viewModel.selectedLanguage },
                        set: { viewModel.setLanguage($0) }
                    )) {
                        Text(String(localized: "settings.language.turkish"))
                            .tag("tr")
                        Text(String(localized: "settings.language.english"))
                            .tag("en")
                    } label: {
                        Label(
                            String(localized: "settings.language.label"),
                            systemImage: "globe"
                        )
                    }
                } header: {
                    Text(String(localized: "settings.section.preferences"))
                }

                // Privacy
                Section {
                    Toggle(isOn: Binding(
                        get: { viewModel.isAnalyticsEnabled },
                        set: { viewModel.setAnalytics($0) }
                    )) {
                        Label(
                            String(localized: "settings.analytics.toggle"),
                            systemImage: "chart.bar"
                        )
                    }
                    Toggle(isOn: Binding(
                        get: { viewModel.isCrashlyticsEnabled },
                        set: { viewModel.setCrashlytics($0) }
                    )) {
                        Label(
                            String(localized: "settings.crashlytics.toggle"),
                            systemImage: "exclamationmark.bubble"
                        )
                    }
                } header: {
                    Text(String(localized: "settings.section.privacy"))
                }

                // Data
                Section {
                    NavigationLink {
                        DataManagementView()
                    } label: {
                        Label(
                            String(localized: "settings.deleteData.button"),
                            systemImage: "trash"
                        )
                    }
                } header: {
                    Text(String(localized: "settings.section.data"))
                }

                // About
                Section {
                    HStack {
                        Text(String(localized: "settings.about.version"))
                            .minimumScaleFactor(0.85)
                        Spacer()
                        Text(Bundle.main.releaseVersionNumber)
                            .foregroundStyle(ColorTokens.textTertiary)
                            .minimumScaleFactor(0.85)
                    }
                    if let privacyURL = URL(string: "https://vade.app/privacy") {
                        Link(
                            String(localized: "settings.about.privacyPolicy"),
                            destination: privacyURL
                        )
                    }
                } header: {
                    Text(String(localized: "settings.section.about"))
                }
            }
            .navigationTitle(String(localized: "settings.navigationTitle"))
            .scrollContentBackground(.hidden)
            .background(ColorTokens.background)
        }
    }
}

#Preview {
    SettingsView()
}
