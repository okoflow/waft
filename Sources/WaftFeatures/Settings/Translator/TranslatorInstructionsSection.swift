import SwiftUI
import WaftCore

struct TranslatorInstructionsSection: View {
    let settings: SettingsModel
    let pro: ProModel
    let state: SettingsWindowState

    var body: some View {
        SettingsSection("Instructions", subtitle: "What the AI model is told to do with your text.", isPro: true) {
            DividedForEach(TextTask.Kind.allCases, id: \.self) { kind in
                InstructionsRow(
                    kind: kind,
                    isEdited: settings.settings.translator.instructions.isCustomized(kind),
                ) {
                    edit(kind)
                }
            }
        }
    }

    func edit(_ kind: TextTask.Kind) {
        guard state.passesWaftPlusGate(isUnlocked: pro.isUnlocked) else { return }

        state.editedTextTask = kind
    }
}

private struct InstructionsRow: View {
    let kind: TextTask.Kind
    let isEdited: Bool
    let edit: () -> Void

    var body: some View {
        Button(action: edit) {
            HStack(spacing: Metrics.accessorySpacing) {
                VStack(alignment: .leading, spacing: Metrics.labelSpacing) {
                    HStack(spacing: Metrics.inlineSpacing) {
                        Text(kind.title)
                            .font(.rowTitle)

                        if isEdited {
                            Badge("Edited")
                                .transition(.opacity)
                        }
                    }

                    Text(kind.summary)
                        .detailText()
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.forward")
                    .font(.glyph)
                    .foregroundStyle(Palette.secondaryText)
                    .frame(width: Metrics.controlHeight, height: Metrics.controlHeight)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Edit \(kind.title)"))
        .motion(Motion.feedback, value: isEdited)
        .settingsRowPadding()
    }
}
