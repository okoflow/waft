import SwiftUI
import WaftCore

struct LanguageMenu: View {
    let settings: SettingsModel
    let chooseLanguages: () -> Void

    private var languageNames: String {
        settings.settings.languages.languages.map(\.displayName).formatted(.list(type: .and, width: .narrow))
    }

    var body: some View {
        Menu("Language: \(settings.pinnedLanguageTitle)") {
            Picker("Language", selection: settings.pinnedLanguage) {
                Text("Automatic (\(languageNames))").tag(Language?.none)

                ForEach(settings.settings.languages.languages, id: \.self) { language in
                    Text(language.displayName).tag(Language?.some(language))
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()

            Divider()

            Button("Choose Languages…", action: chooseLanguages)
        }
    }
}
