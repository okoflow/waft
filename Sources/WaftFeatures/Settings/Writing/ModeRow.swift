import SwiftUI
import WaftCore

struct ModeRow: View {
    let mode: Mode
    let settings: SettingsModel
    let isLocked: Bool
    let state: SettingsWindowState

    private var isSelected: Bool {
        settings.settings.mode == mode
    }

    var body: some View {
        HStack(spacing: Metrics.accessorySpacing) {
            Button(action: select) {
                HStack(spacing: 0) {
                    ModeLabel(mode: mode, settings: settings.settings)

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])

            ZStack {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.sectionTitle)
                        .foregroundStyle(Palette.accent)
                        .transition(.opacity)
                }
            }
            .frame(width: 14)
            .animation(Motion.feedback, value: isSelected)
            .accessibilityHidden(true)

            Button(action: edit) {
                Image(systemName: "chevron.forward")
                    .font(.glyph)
                    .foregroundStyle(.secondary)
                    .frame(width: Metrics.controlHeight, height: Metrics.controlHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Edit the mode")
            .accessibilityLabel(Text("Edit \(settings.settings.title(of: mode))"))
            .opacity(mode.usesAI ? 1 : 0)
            .disabled(!mode.usesAI)
            .allowsHitTesting(mode.usesAI)
            .accessibilityHidden(!mode.usesAI)
        }
        .settingsRowPadding()
    }

    private func select() {
        guard !isLocked else {
            state.selection = .pro

            return
        }

        settings.settings.mode = mode
    }

    private func edit() {
        guard !isLocked else {
            state.selection = .pro

            return
        }

        state.editedMode = mode
    }
}

private struct ModeLabel: View {
    let mode: Mode
    let settings: WaftCore.Settings

    private var provider: ModelProvider {
        settings.modelProvider
    }

    private var processingNote: Text {
        provider.isCloud
            ? Text("Sends the recognized text to \(provider.title)")
            : Text("Runs on this Mac with \(provider.title)")
    }

    private var isBuiltIn: Bool {
        Mode.builtIn.contains(mode)
    }

    private var isEdited: Bool {
        isBuiltIn && mode.usesAI && settings.instructions.isCustomized(mode)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.labelSpacing) {
            HStack(spacing: Metrics.inlineSpacing) {
                Text(settings.title(of: mode))
                    .font(.rowTitle)

                if mode.usesAI {
                    Image(systemName: provider.isCloud ? "cloud" : "cpu")
                        .font(.glyph)
                        .foregroundStyle(.secondary)
                        .help(processingNote)
                        .accessibilityLabel(processingNote)
                }

                if isBuiltIn, mode.usesAI {
                    ProBadge()
                }

                if isEdited {
                    Badge("Edited")
                        .transition(.opacity)
                }
            }

            Text(settings.summary(of: mode))
                .font(.rowDetail)
                .foregroundStyle(.secondary)
                .lineLimit(isBuiltIn ? nil : 1)
        }
        .animation(Motion.feedback, value: isEdited)
    }
}
