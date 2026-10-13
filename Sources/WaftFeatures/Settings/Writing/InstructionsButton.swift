import SwiftUI
import WaftCore

struct InstructionsButton: View {
    let mode: Mode
    let provider: ModelProvider
    let settings: SettingsModel
    let state: SettingsWindowState

    private var isPresented: Binding<Bool> {
        Binding(
            get: { state.editedInstructions == mode },
            set: { isPresented in
                if isPresented {
                    state.editedInstructions = mode
                } else if state.editedInstructions == mode {
                    state.editedInstructions = nil
                }
            },
        )
    }

    var body: some View {
        Button("Instructions…") {
            state.editedInstructions = mode
        }
        .popover(isPresented: isPresented, arrowEdge: .bottom) {
            InstructionsEditor(mode: mode, provider: provider, settings: settings) {
                state.editedInstructions = nil
            }
        }
    }
}

private struct InstructionsEditor: View {
    let mode: Mode
    let provider: ModelProvider
    let settings: SettingsModel
    let close: () -> Void

    private var text: Binding<String> {
        Binding(
            get: { settings.settings.instructions.editableText(for: mode) },
            set: { settings.settings.instructions.set($0, for: mode) },
        )
    }

    private var isCustomized: Bool {
        settings.settings.instructions.isCustomized(mode)
    }

    private var subtitle: Text {
        provider.isCloud
            ? Text("Instructions sent to \(provider.title) with your text.")
            : Text("Instructions for \(provider.title) on this Mac.")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(mode.title)
                    .font(.sectionTitle)

                subtitle
                    .font(.rowDetail)
                    .foregroundStyle(.secondary)
            }

            InputEditor(text: text)
                .frame(width: 440, height: 200)

            HStack {
                Button("Reset to Default") { settings.settings.instructions.reset(mode) }
                    .disabled(!isCustomized)

                Spacer()

                Button("Done", action: close)
                    .buttonStyle(PushButtonStyle(isProminent: true))
            }
        }
        .buttonStyle(PushButtonStyle())
        .padding(16)
    }
}
