import SwiftUI

struct ProgressCard: View {
    let model: FileTranscriptionModel
    let file: URL

    private var progress: Double? {
        guard case let .transcribing(_, progress) = model.phase else { return nil }

        return progress
    }

    private var status: String {
        guard let progress else { return String(localized: "Reading the audio…") }

        return String(localized: "Transcribing… \(progress.formatted(.percent.precision(.fractionLength(0))))")
    }

    var body: some View {
        SettingsCard {
            HStack(spacing: Metrics.accessorySpacing) {
                FileIcon(url: file)

                VStack(alignment: .leading, spacing: Metrics.inlineSpacing) {
                    Text(file.lastPathComponent)
                        .font(.rowTitle)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .opacity(progress == nil ? 0.4 : 1)
                        .motion(Motion.meter, value: progress)

                    Text(status)
                        .font(.rowDetail)
                        .foregroundStyle(Palette.secondaryText)
                        .monospacedDigit()
                }

                Button("Cancel", action: model.cancel)
            }
            .settingsRowPadding()
        }
    }
}
