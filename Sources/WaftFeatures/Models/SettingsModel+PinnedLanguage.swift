import Foundation
import WaftCore

extension SettingsModel {
    var pinnedLanguage: Language? {
        get { settings.languages.pinned }
        set { settings.languages = settings.languages.pinning(newValue) }
    }

    var pinnedLanguageTitle: String {
        guard let pinned = settings.languages.pinned else { return String(localized: "Automatic") }

        return pinned.displayName
    }
}
