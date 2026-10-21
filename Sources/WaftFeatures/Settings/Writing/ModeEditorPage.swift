import SwiftUI
import WaftCore

struct ModeEditorPage: View {
    let mode: Mode
    let settings: SettingsModel
    let tryout: TryoutModel
    let state: SettingsWindowState

    private var custom: CustomMode? {
        guard case let .custom(id) = mode else { return nil }

        return settings.settings.customMode(id)
    }

    private var instructions: Binding<String> {
        guard let custom else {
            return Binding(
                get: { settings.settings.instructions.editableText(for: mode) },
                set: { settings.settings.instructions.set($0, for: mode) },
            )
        }

        return binding(\.instructions, of: custom)
    }

    var body: some View {
        SettingsPage(.verbatim(settings.settings.title(of: mode)), needsWaftPlus: mode.usesAI, back: close) {
            if let custom {
                Button("Delete Mode…", role: .destructive) { delete(custom) }
            } else {
                ResetInstructionsButton(
                    title: settings.settings.title(of: mode),
                    isCustomized: settings.settings.instructions.isCustomized(mode),
                ) {
                    settings.settings.instructions.reset(mode)
                }
            }
        } content: {
            if let custom {
                SettingsSection("Name") {
                    InputField("Name", prompt: "Mode name", text: binding(\.name, of: custom))
                        .settingsRowPadding()
                }
            }

            InstructionsSection(settings: settings, instructions: instructions)

            TryoutSection(
                tryout: tryout,
                sampleTitle: "You say",
                samplePrompt: "Say something to try",
                idleNote: "Run the mode to see what it writes.",
            ) {
                tryout.run(mode)
            }
        }
        .onAppear(perform: tryout.reset)
    }

    func binding(_ field: WritableKeyPath<CustomMode, String>, of custom: CustomMode) -> Binding<String> {
        Binding(
            get: {
                guard let current = settings.settings.customMode(custom.id) else { return "" }

                return current[keyPath: field]
            },
            set: { text in
                guard var edited = settings.settings.customMode(custom.id) else { return }

                edited[keyPath: field] = text

                settings.settings.update(edited)
            },
        )
    }

    private func close() {
        state.editedMode = nil
    }

    private func delete(_ custom: CustomMode) {
        let confirmation = Confirmation(
            message: String(localized: "Delete “\(settings.settings.title(of: mode))”?"),
            detail: String(localized: "Apps that use this mode go back to the default mode."),
            action: String(localized: "Delete Mode"),
        )

        guard confirmation.ask() else { return }

        close()
        settings.settings.removeCustomMode(custom.id)
    }
}
