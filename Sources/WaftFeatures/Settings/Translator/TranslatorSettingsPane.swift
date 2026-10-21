import SwiftUI
import WaftCore

struct TranslatorSettingsPane: View {
    @Bindable var settings: SettingsModel

    let shortcuts: GlobalShortcutController
    let shortcutRecorder: ShortcutRecorder
    let pro: ProModel
    let state: SettingsWindowState
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

    var body: some View {
        TranslationSection(
            title: "Languages",
            subtitle: languagesNote,
            translation: $settings.settings.translator.translation,
        )

        TranslatorInstructionsSection(settings: settings, pro: pro, state: state)

        TranslatorModelSection(settings: settings, state: state)

        SettingsSection("Shortcuts", subtitle: "They work in any app.") {
            shortcutRow(.translator)
            RowDivider()
            shortcutRow(.translateSelection, description: "Replaces the selection with its translation.")
            RowDivider()
            shortcutRow(.fixSelection, description: "Corrects spelling, grammar, and punctuation in the selection.")
        } footer: {
            Button("Open Translator", action: openTranslator)
        }
        .onDisappear { shortcutRecorder.stop() }
    }

    private func shortcutRow(_ action: ShortcutAction, description: LocalizedStringKey? = nil) -> some View {
        ShortcutRow(
            action: action,
            settings: settings,
            shortcuts: shortcuts,
            recorder: shortcutRecorder,
            description: description,
        )
    }
}
