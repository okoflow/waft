import SwiftUI
import WaftCore

struct TranslationSection: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    var needsWaftPlus = false

    @Binding var translation: WaftCore.Translation

    private var twoWayTitle: String {
        guard let language = translation.twoWayLanguage else { return String(localized: "Off") }

        return language.displayName
    }

    var body: some View {
        SettingsSection(title, subtitle: subtitle, needsWaftPlus: needsWaftPlus) {
            PickerRow("Translate into", selection: $translation.target, current: translation.target.displayName) {
                ForEach(Language.allByDisplayName, id: \.self) { language in
                    Text(language.displayName).tag(language)
                }
            }
            RowDivider()
            PickerRow("Two-way with", selection: $translation.twoWayLanguage, current: twoWayTitle) {
                Text("Off").tag(Language?.none)
                Divider()
                ForEach(Language.allByDisplayName.filter { $0 != translation.target }, id: \.self) { language in
                    Text(language.displayName).tag(Language?.some(language))
                }
            }
        }
    }
}
