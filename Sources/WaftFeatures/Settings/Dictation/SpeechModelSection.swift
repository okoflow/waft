import SwiftUI
import WaftCore

struct SpeechModelSection: View {
    let settings: SettingsModel
    let controller: SpeechModelController
    let pro: ProModel
    let state: SettingsWindowState

    var body: some View {
        SettingsGroup("Speech model", subtitle: "Whisper runs on this Mac, so audio never leaves it.") {
            HStack(alignment: .top, spacing: Metrics.controlSpacing) {
                ForEach(SpeechModel.allCases, id: \.self) { model in
                    PickerCard(
                        .verbatim(model.title),
                        detail: .verbatim(model.summary),
                        isSelected: controller.chosenModel == model,
                        needsWaftPlus: model.needsWaftPlus,
                    ) {
                        choose(model)
                    } preview: {
                        SpeechModelPreview(model: model)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)

            SettingsCard {
                SettingsRow(.verbatim(controller.state.statusText)) {
                    if let progress = controller.state.progress {
                        ProgressView(value: progress)
                            .frame(width: 100)
                    }

                    if controller.state.canRetry {
                        Button("Retry", action: controller.retry)
                    }

                    Button("Show in Finder", action: controller.revealInFinder)
                }
            }
        }
    }

    private func choose(_ model: SpeechModel) {
        guard state.passesWaftPlusGate(isUnlocked: !pro.locks(model)) else { return }

        settings.settings.speechModel = model
    }
}

private struct SpeechModelPreview: View {
    let model: SpeechModel

    private var barHeights: [CGFloat] {
        switch model {
        case .fast: [8, 14, 20, 14, 8]
        case .accurate: [8, 14, 20, 26, 20, 14, 8]
        }
    }

    private var name: String {
        switch model {
        case .fast: "Whisper turbo"
        case .accurate: "Whisper large-v3"
        }
    }

    var body: some View {
        HStack(spacing: Metrics.controlSpacing) {
            HStack(spacing: 3) {
                ForEach(Array(barHeights.enumerated()), id: \.offset) { _, height in
                    Capsule()
                        .fill(Palette.accent)
                        .frame(width: 4, height: height)
                }
            }

            Text(verbatim: name)
                .font(.previewLabel)
                .foregroundStyle(Palette.secondaryText)
        }
        .accessibilityHidden(true)
    }
}
