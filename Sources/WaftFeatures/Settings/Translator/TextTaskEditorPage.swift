import SwiftUI
import WaftCore

struct TextTaskEditorPage: View {
    let kind: TextTask.Kind
    let settings: SettingsModel
    let tryout: TryoutModel
    let state: SettingsWindowState

    private var instructions: Binding<String> {
        Binding(
            get: { settings.settings.translator.instructions.editableText(for: kind) },
            set: { settings.settings.translator.instructions.set($0, for: kind) },
        )
    }

    var body: some View {
        SettingsPage(.verbatim(kind.title), needsWaftPlus: true, back: state.closeEditor) {
            ResetInstructionsButton(
                title: kind.title,
                isCustomized: settings.settings.translator.instructions.isCustomized(kind),
            ) {
                settings.settings.translator.instructions.reset(kind)
            }
        } content: {
            InstructionsSection(settings: settings, instructions: instructions)

            TryoutSection(
                tryout: tryout,
                sampleTitle: "You write",
                samplePrompt: "Type something to try",
                idleNote: "Run it to see what Waft writes.",
            ) {
                tryout.run(task: kind)
            }
        }
        .onAppear(perform: tryout.reset)
    }
}
