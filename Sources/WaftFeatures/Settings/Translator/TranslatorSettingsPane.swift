import SwiftUI
import WaftCore

struct TranslatorSettingsPane: View {
    @Bindable var settings: SettingsModel

    let shortcuts: TranslatorShortcuts
    let openTranslator: () -> Void

    private var translation: WaftCore.Translation {
        settings.settings.translator.translation
    }

    private var languagesNote: LocalizedStringKey {
        let target = translation.target.inlineName

        guard let other = translation.twoWayLanguage?.inlineName else {
            return .verbatim(String(localized: "Text in any language becomes \(target)."))
        }

        return .verbatim(String(localized: "Text in \(other) becomes \(target), and \(target) becomes \(other).").sentenceCased())
    }

    private var twoWayTitle: String {
        guard let language = translation.twoWayLanguage else { return String(localized: "Off") }

        return language.displayName
    }

    var body: some View {
        SettingsSection("Languages", subtitle: languagesNote, isPro: true) {
            PickerRow(
                "Translate into",
                selection: $settings.settings.translator.translation.target,
                current: translation.target.displayName,
            ) {
                ForEach(Language.allByDisplayName, id: \.self) { language in
                    Text(language.displayName).tag(language)
                }
            }
            RowDivider()
            PickerRow(
                "Two-way with",
                selection: $settings.settings.translator.translation.twoWayLanguage,
                current: twoWayTitle,
            ) {
                Text("Off").tag(Language?.none)
                Divider()
                ForEach(Language.allByDisplayName.filter { $0 != translation.target }, id: \.self) { language in
                    Text(language.displayName).tag(Language?.some(language))
                }
            }
        }

        SettingsSection("Wording", isPro: true) {
            ToggleRow(
                "Make it clearer",
                isOn: $settings.settings.translator.rephrases,
                description: "Translations and fixes also untangle long sentences and put the points in order.",
            )
        }

        SettingsSection("Shortcuts", subtitle: "They work in any app.") {
            ShortcutRow("Open the translator", keys: shortcuts.translatorTitle)
            RowDivider()
            ShortcutRow(
                "Translate selected text",
                keys: shortcuts.translateSelectionTitle,
                description: "Replaces the selection with its translation.",
            )
            RowDivider()
            ShortcutRow(
                "Fix selected text",
                keys: shortcuts.fixSelectionTitle,
                description: "Corrects spelling, grammar, and punctuation in the selection.",
            )
        } footer: {
            Button("Open Translator", action: openTranslator)
        }
    }
}

private struct ShortcutRow: View {
    private let title: LocalizedStringKey
    private let keys: String?
    private let description: LocalizedStringKey?

    init(_ title: LocalizedStringKey, keys: String?, description: LocalizedStringKey? = nil) {
        self.title = title
        self.keys = keys
        self.description = description
    }

    var body: some View {
        SettingsRow(title, description: description) {
            if let keys {
                Text(verbatim: keys)
                    .font(.control)
                    .padding(.horizontal, Metrics.controlSpacing)
                    .frame(height: Metrics.controlHeight)
                    .background(Palette.control, in: RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous))
                    .accessibilityLabel(Text(verbatim: keys))
            } else {
                Text("Unavailable")
                    .detailText()
            }
        }
    }
}
