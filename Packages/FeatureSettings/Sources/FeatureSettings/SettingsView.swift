import SwiftUI
import DesignSystem

// MARK: - Settings View

public struct SettingsView: View {
    @State private var isBiometricEnabled = false
    @State private var selectedLanguage = "tr"
    @State private var isAnalyticsEnabled = true
    @State private var isCrashlyticsEnabled = true

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
                            .foregroundColor(Color("ink400", bundle: .module))
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
                            .foregroundColor(Color("ink400", bundle: .module))
                    }
                    Link(
                        String(localized: "settings.about.privacyPolicy"),
                        destination: URL(string: "https://vade.app/privacy")!
                    )
                } header: {
                    Text(String(localized: "settings.section.about"))
                }
            }
            .navigationTitle(String(localized: "settings.navigationTitle"))
            .background(Color("background", bundle: .module))
        }
    }
}

#Preview {
    SettingsView()
}
