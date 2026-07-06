import SwiftUI
import DesignSystem

// MARK: - Settings View

public struct SettingsView: View {
    @AppStorage("vade.biometric.enabled") private var isBiometricEnabled = false
    @AppStorage("vade.language") private var selectedLanguage = "tr"
    @AppStorage("vade.analytics.enabled") private var isAnalyticsEnabled = true
    @AppStorage("vade.crashlytics.enabled") private var isCrashlyticsEnabled = true

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                // Security
                Section {
                    Toggle(isOn: $isBiometricEnabled) {
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
                    HStack {
                        Label(
                            String(localized: "settings.language.label"),
                            systemImage: "globe"
                        )
                        Spacer()
                        Text(selectedLanguage == "tr" ? "Türkçe" : "English")
                            .foregroundColor(Color.vdInk400)
                    }
                } header: {
                    Text(String(localized: "settings.section.preferences"))
                }

                // Privacy
                Section {
                    Toggle(isOn: $isAnalyticsEnabled) {
                        Label(
                            String(localized: "settings.analytics.toggle"),
                            systemImage: "chart.bar"
                        )
                    }
                    Toggle(isOn: $isCrashlyticsEnabled) {
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
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(Color.vdInk400)
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
            .background(Color.vdBackground)
        }
    }
}

#Preview {
    SettingsView()
}
