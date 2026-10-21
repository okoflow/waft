import SwiftUI
import WaftCore

struct EditKeySection: View {
    let settings: SettingsModel
    let keyRecorder: KeyRecorder
    let isLocked: Bool
    let showPro: () -> Void

    var body: some View {
        SettingsSection(
            "Editing by voice",
            subtitle: "Select text, hold the key, and say what to change, like “make it shorter”.",
            isPro: true,
        ) {
            SettingsRow("Editing key", description: keyRecorder.note(for: .edit)) {
                if isLocked {
                    Button("Unlock Waft+…", action: showPro)
                } else {
                    recorder
                }
            }
            .motion(Motion.feedback, value: settings.settings.editKey)
        }
    }

    @ViewBuilder
    private var recorder: some View {
        KeyRecorderField(
            purpose: .edit,
            key: settings.settings.editKey,
            takenKey: settings.settings.pushToTalkKey,
            recorder: keyRecorder,
        ) { key in
            settings.settings.editKey = key
        }

        if settings.settings.editKey != nil {
            RemoveButton(help: "Turn off editing by voice") {
                settings.settings.editKey = nil
            }
            .transition(.opacity)
        }
    }
}
