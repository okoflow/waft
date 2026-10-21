import SwiftUI
import WaftCore

struct InstructionsSection: View {
    let settings: SettingsModel
    let instructions: Binding<String>

    private var note: LocalizedStringKey {
        let provider = settings.settings.modelProvider

        guard !provider.isCloud, settings.settings.localServer.isOnThisMac else {
            return "Sent to \(provider.title) with your text."
        }

        return "Used by \(provider.title) on this Mac."
    }

    var body: some View {
        SettingsGroup("Instructions", subtitle: note) {
            InputEditor(text: instructions)
                .frame(height: Metrics.instructionsHeight)
        }
    }
}
