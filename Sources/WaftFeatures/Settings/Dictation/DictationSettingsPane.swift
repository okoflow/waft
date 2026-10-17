import Foundation
import SwiftUI
import WaftCore

struct DictationSettingsPane: View {
    @Bindable var settings: SettingsModel

    let speechModelController: SpeechModelController
    let keyRecorder: KeyRecorder
    let pro: ProModel
    let state: SettingsWindowState

    private var selection: LanguageSelection {
        settings.settings.languages
    }

    private var pinnedLanguage: Binding<Language?> {
        Binding(
            get: { selection.pinned },
            set: { settings.settings.languages = selection.pinning($0) },
        )
    }

    private var spokenLanguageNote: LocalizedStringKey? {
        let alike = Language.soundAlike(among: selection.languages)
        guard !alike.isEmpty else { return nil }

        let names = Language.inlineList(alike)
        let note = String(localized: "\(names) sound alike. If Waft mixes them up, choose one as the spoken language.")

        return .verbatim(note.sentenceCased())
    }

    private var suggestedLanguages: [Language] {
        selection.suggestions(from: Locale.preferredLanguages)
    }

    private var keyNote: LocalizedStringKey? {
        if let note = keyRecorder.note(for: .dictation) {
            return note
        }

        return settings.settings.pushToTalkKey == .function
            ? "Set “Press 🌐 key to” to Do Nothing in System Settings › Keyboard."
            : nil
    }

    private var microphoneName: String {
        guard let microphone = settings.microphones.first(where: { $0.id == settings.settings.microphoneID }) else {
            return String(localized: "System default")
        }

        return microphone.name
    }

    private var pinnedTitle: String {
        guard let pinned = selection.pinned else { return String(localized: "Automatic") }

        return pinned.displayName
    }

    private var addableLanguages: [Language] {
        Language.allByDisplayName.filter { !selection.languages.contains($0) }
    }

    var body: some View {
        DictationStartSection(settings: settings)

        SettingsSection("Recording") {
            SettingsRow("Dictation key", description: keyNote) {
                KeyRecorderField(
                    purpose: .dictation,
                    key: settings.settings.pushToTalkKey,
                    takenKey: settings.settings.editKey,
                    recorder: keyRecorder,
                ) { key in
                    settings.settings.pushToTalkKey = key
                }
            }
            RowDivider()
            PickerRow("Microphone", selection: $settings.settings.microphoneID, current: microphoneName) {
                Text("System default").tag(String?.none)
                ForEach(settings.microphones) { microphone in
                    Text(microphone.name).tag(String?.some(microphone.id))
                }
            }
        }
        .onAppear(perform: settings.refreshMicrophones)

        SpeechModelSection(settings: settings, controller: speechModelController, pro: pro, state: state)

        EditKeySection(settings: settings, keyRecorder: keyRecorder, isLocked: !pro.isUnlocked) {
            state.selection = .pro
        }

        SettingsSection("Languages", subtitle: "Waft listens for these languages.") {
            ForEach(selection.languages, id: \.self) { language in
                LanguageRow(language: language, settings: settings, canRemove: selection.languages.count > 1) {
                    settings.settings.languages = selection.removing(language)
                }
                .rowTransition()
                RowDivider()
                    .rowTransition()
            }

            PickerRow(
                "Spoken language",
                selection: pinnedLanguage,
                current: pinnedTitle,
                description: spokenLanguageNote,
            ) {
                Text("Automatic").tag(Language?.none)
                Divider()
                ForEach(selection.languages, id: \.self) { language in
                    Text(language.displayName).tag(Language?.some(language))
                }
            }
        } footer: {
            Menu {
                if !suggestedLanguages.isEmpty {
                    Section("Suggested") {
                        ForEach(suggestedLanguages, id: \.self) { language in
                            AddLanguageButton(language: language, settings: settings)
                        }
                    }
                }

                Section("All Languages") {
                    ForEach(addableLanguages, id: \.self) { language in
                        AddLanguageButton(language: language, settings: settings)
                    }
                }
            } label: {
                Label("Add Language", systemImage: "plus")
            }
            .menuStyle(.button)
            .menuIndicator(.hidden)
            .fixedSize()
            .disabled(addableLanguages.isEmpty)
        }
        .animation(Motion.layout, value: selection.languages)
        .onDisappear { keyRecorder.stop() }
    }
}

private struct AddLanguageButton: View {
    let language: Language
    let settings: SettingsModel

    private var title: String {
        language.displayName == language.nativeName ? language.displayName : "\(language.displayName) · \(language.nativeName)"
    }

    var body: some View {
        Button(title) {
            settings.settings.languages = settings.settings.languages.adding(language)
        }
    }
}

private struct LanguageRow: View {
    let language: Language
    let settings: SettingsModel
    let canRemove: Bool
    let remove: () -> Void

    var body: some View {
        SettingsRow(
            .verbatim(language.nativeName),
            description: language.nativeName == language.displayName ? nil : .verbatim(language.displayName),
        ) {
            if let chosen = settings.settings.writingVariants.variant(for: language) {
                MenuPicker("Writing system", selection: variantBinding(showing: chosen), current: chosen.nativeName) {
                    ForEach(language.writingVariants, id: \.self) { variant in
                        Text(verbatim: variant.nativeName).tag(variant)
                    }
                }
            }

            RemoveButton(help: "Remove \(language.displayName)", action: remove)
                .disabled(!canRemove)
        }
    }

    private func variantBinding(showing chosen: WritingVariant) -> Binding<WritingVariant> {
        Binding(
            get: { chosen },
            set: { settings.settings.writingVariants = settings.settings.writingVariants.choosing($0, for: language) },
        )
    }
}
