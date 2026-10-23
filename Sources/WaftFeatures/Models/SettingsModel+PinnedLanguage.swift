import SwiftUI
import WaftCore

extension SettingsModel {
    var pinnedLanguage: Binding<Language?> {
        Binding(
            get: { self.settings.languages.pinned },
            set: { self.settings.languages = self.settings.languages.pinning($0) },
        )
    }

    var pinnedLanguageTitle: String {
        guard let pinned = settings.languages.pinned else { return String(localized: "Automatic") }

        return pinned.displayName
    }
}
