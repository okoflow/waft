import SwiftUI
import WaftCore

struct ModeEditorPage: View {
    let mode: Mode
    let settings: SettingsModel
    let tryout: ModeTryoutModel
    let state: SettingsWindowState

    private var custom: CustomMode? {
        guard case let .custom(id) = mode else { return nil }

        return settings.settings.customMode(id)
    }

    private var provider: ModelProvider {
        settings.settings.modelProvider
    }

    private var instructionsNote: LocalizedStringKey {
        provider.isCloud
            ? "Sent to \(provider.title) with your text."
            : "Used by \(provider.title) on this Mac."
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
                Button("Reset to Default") { settings.settings.instructions.reset(mode) }
                    .disabled(!settings.settings.instructions.isCustomized(mode))
            }
        } content: {
            if let custom {
                SettingsSection("Name") {
                    InputField("Name", prompt: "Mode name", text: binding(\.name, of: custom))
                        .settingsRowPadding()
                }
            }

            SettingsGroup("Instructions", subtitle: instructionsNote) {
                InputEditor(text: instructions)
                    .frame(height: Metrics.instructionsHeight)
            }

            TryoutSection(mode: mode, tryout: tryout, provider: provider)
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

private struct TryoutSection: View {
    let mode: Mode
    @Bindable var tryout: ModeTryoutModel

    let provider: ModelProvider

    var body: some View {
        SettingsSection("Try it") {
            VStack(alignment: .leading, spacing: Metrics.labelSpacing) {
                Text("You say")
                    .font(.rowDetail)
                    .foregroundStyle(.secondary)

                InputField("You say", prompt: "Say something to try", text: $tryout.sample)
            }
            .settingsRowPadding()

            RowDivider()

            HStack(spacing: Metrics.rowSpacing) {
                VStack(alignment: .leading, spacing: Metrics.labelSpacing) {
                    Text("Waft writes")
                        .font(.rowDetail)
                        .foregroundStyle(.secondary)

                    result
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(tryout.phase == .idle ? "Run" : "Run Again") { tryout.run(mode) }
                    .disabled(tryout.phase == .running || tryout.sample.isBlank)
            }
            .settingsRowPadding()
        }
    }

    @ViewBuilder
    private var result: some View {
        switch tryout.phase {
        case .idle:
            Text("Run the mode to see what it writes.")
                .font(.rowTitle)
                .foregroundStyle(.tertiary)

        case .running:
            ProgressView()
                .controlSize(.small)

        case let .finished(processed):
            Text(processed.text)
                .font(.rowTitle)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentDirection(of: processed.text)
                .fixedSize(horizontal: false, vertical: true)

            if let fallback = processed.fallback {
                Text(fallback.message(for: provider))
                    .font(.rowDetail)
                    .foregroundStyle(Palette.warning)
            }
        }
    }
}
