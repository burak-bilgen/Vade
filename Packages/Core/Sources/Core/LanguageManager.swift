import Foundation
import Observation

// MARK: - Language Manager

/// Manages in-app language selection WITHOUT requiring an app restart.
/// Uses SwiftUI's `.environment(\.locale, ...)` and `.id(languageCode)` 
/// to force an immediate view tree rebuild with the new locale.
/// 
/// NOTE: `String(localized:)` reads from the system language (requires restart),
/// so use `localized(_:)` helper for non-Text contexts, and plain Text("key")
/// (which auto-creates LocalizedStringKey) for Text contexts.
@available(macOS 14.0, iOS 17.0, *)
@MainActor
@Observable
public final class LanguageManager {
    @ObservationIgnored
    public nonisolated static let shared = MainActor.assumeIsolated { LanguageManager() }

    private let defaults = UserDefaults(suiteName: UserDefaultsKeys.appGroupSuite) ?? .standard

    /// The current language code (e.g. "tr", "en").
    public var languageCode: String {
        didSet {
            defaults.set(languageCode, forKey: UserDefaultsKeys.appLanguage)
            defaults.set([languageCode], forKey: "AppleLanguages")
        }
    }

    /// The current locale derived from `languageCode`.
    /// Used via `.environment(\.locale, languageManager.locale)` to propagate to all Text views.
    public var locale: Locale {
        Locale(identifier: languageCode)
    }

    public init() {
        let defaults = UserDefaults(suiteName: UserDefaultsKeys.appGroupSuite) ?? .standard
        let code = defaults.string(forKey: UserDefaultsKeys.appLanguage)
            ?? Locale.current.language.languageCode?.identifier
            ?? "tr"
        self.languageCode = code
    }

    /// Changes the language and persists the selection to UserDefaults.
    /// The view tree rebuilds automatically via `.id(languageCode)` in the root view,
    /// and the new locale is applied via the `\.locale` environment value.
    public func setLanguage(_ code: String) {
        guard code != languageCode else { return }
        languageCode = code
    }

    /// Returns a localized string for the current locale.
    /// Use this instead of `String(localized:)` for non-Text contexts
    /// (e.g., accessibility labels, share text, tab titles).
    public nonisolated func localized(_ key: String.LocalizationValue, comment: StaticString? = nil) -> String {
        let defaults = UserDefaults(suiteName: UserDefaultsKeys.appGroupSuite) ?? .standard
        let code = defaults.string(forKey: UserDefaultsKeys.appLanguage) ?? "tr"
        let locale = Locale(identifier: code)
        return String(localized: key, locale: locale)
    }
}
