import AppKit
import SwiftUI
import WaftCore

struct SpeechModelSection: View {
    let settings: SettingsModel
    let controller: SpeechModelController
    let pro: ProModel
    let state: SettingsWindowState

    private var chosenModel: SpeechModel {
        settings.settings.speechModel.usable(withProUnlocked: pro.isUnlocked)
    }

    var body: some View {
        SettingsSection("Speech recognition", subtitle: "Whisper runs on this Mac, so audio never leaves it.") {
            DividedForEach(SpeechModel.allCases, id: \.self) { model in
                SpeechModelRow(model: model, isSelected: chosenModel == model) {
                    choose(model)
                }
            }

            RowDivider()

            SettingsRow(.verbatim(controller.state.statusText)) {
                if let progress = controller.state.progress {
                    ProgressView(value: progress)
                        .frame(width: 100)
                }

                if controller.state.canRetry {
                    Button("Retry") { controller.retry() }
                }

                Button("Show in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([controller.modelDirectory])
                }
            }
        }
    }

    private func choose(_ model: SpeechModel) {
        guard !pro.locks(model) else {
            state.selection = .pro

            return
        }

        settings.settings.speechModel = model
    }
}

private struct SpeechModelRow: View {
    let model: SpeechModel
    let isSelected: Bool
    let choose: () -> Void

    var body: some View {
        Button(action: choose) {
            HStack(spacing: Metrics.accessorySpacing) {
                RowLabel(title: .verbatim(model.title), description: .verbatim(model.summary))

                Spacer(minLength: 0)

                if model.needsPro {
                    Badge("Pro", tint: .purple)
                }

                ZStack {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.sectionTitle)
                            .foregroundStyle(.tint)
                            .transition(.opacity)
                    }
                }
                .frame(width: 14)
                .animation(Motion.feedback, value: isSelected)
                .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .settingsRowPadding()
    }
}
