import SwiftUI
import WaftCore

struct ShortcutRow: View {
    let action: ShortcutAction
    let settings: SettingsModel
    let shortcuts: GlobalShortcutController
    let recorder: ShortcutRecorder
    var description: LocalizedStringKey?

    private var combination: KeyCombination? {
        settings.settings.shortcuts[action]
    }

    private var isRecording: Bool {
        recorder.isRecording(action)
    }

    private var note: LocalizedStringKey? {
        if let note = recorder.note(for: action) {
            return note
        }

        guard shortcuts.unavailable.contains(action) else { return description }

        return "Unavailable: another app uses this shortcut. Choose another one."
    }

    private var help: Text {
        guard isRecording else { return Text("Click, then press the shortcut to use") }

        return Text("Press the shortcut to use, or Esc to cancel")
    }

    var body: some View {
        SettingsRow(.verbatim(action.title), description: note) {
            RecorderField(
                title: combination?.title(in: shortcuts.layout),
                isRecording: isRecording,
                prompt: "Press a shortcut…",
                rejections: recorder.rejections[action, default: 0],
                help: help,
                label: Text(verbatim: action.title),
            ) {
                if isRecording {
                    recorder.stop()
                } else {
                    recorder.start(action)
                }
            }

            if settings.settings.shortcuts.canReset(action) {
                IconButton(symbolName: "arrow.counterclockwise", label: "Use the default shortcut") {
                    recorder.reset(action)
                }
                .transition(.opacity)
            }

            if combination != nil {
                RemoveButton(help: "Turn off this shortcut") {
                    recorder.clear(action)
                }
                .transition(.opacity)
            }
        }
        .motion(Motion.feedback, value: combination)
    }
}
