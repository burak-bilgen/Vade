import Foundation
import Observation

// MARK: - Language Manager

/// Manages the app's language selection and notifies observers of changes.
/// When the language changes, the view tree is invalidated so all
/// `String(localized:)` and `Text(...)` calls re-resolve automatically.
@available(macOS 14.0, iOS 17.0, *)
@MainActor
@Observable
public final class LanguageManager {
    /// The current language code (e.g. "tr", "en", "es", "zh", "hi", "ar").
    public var languageCode: String {
        didSet {
            UserDefaults.standard.set(languageCode, forKey: UserDefaultsKeys.appLanguage)
            UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
            locale = Locale(identifier: languageCode)
        }
    }

    /// The current locale derived from `languageCode`.
    public private(set) var locale: Locale

    public init() {
        let code = UserDefaults.standard.string(forKey: UserDefaultsKeys.appLanguage)
            ?? Locale.current.language.languageCode?.identifier
            ?? "tr"
        self.languageCode = code
        self.locale = Locale(identifier: code)
    }

    /// Changes the language and persists the selection to UserDefaults.
    /// The view tree rebuilds automatically via `.id(languageCode)` in the root view.
    public func setLanguage(_ code: String) {
        guard code != languageCode else { return }
        languageCode = code
    }
}
