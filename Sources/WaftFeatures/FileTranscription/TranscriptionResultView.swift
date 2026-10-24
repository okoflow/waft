import AppKit
import SwiftUI
import WaftCore

struct TranscriptionResultView: View {
    private static let transcriptPadding: CGFloat = 12

    let model: FileTranscriptionModel
    let file: URL
    let transcript: TimedTranscript

    private var details: String {
        let duration = Duration.seconds(transcript.duration).formatted(
            .time(pattern: transcript.duration >= 3600 ? .hourMinuteSecond : .minuteSecond),
        )

        return [duration, transcript.language.displayName].joined(separator: " · ")
    }

    var body: some View {
        VStack(spacing: Metrics.accessorySpacing) {
            SettingsCard {
                HStack(spacing: Metrics.iconLabelSpacing) {
                    FileIcon(url: file)

                    RowLabel(title: .verbatim(file.lastPathComponent), description: .verbatim(details))

                    Spacer(minLength: 0)

                    CopyButton(isCopied: model.copyFeedback.isShowing(file), action: model.copyText)
                }
                .settingsRowPadding()

                RowDivider()

                ScrollView {
                    Text(transcript.text)
                        .font(.rowTitle)
                        .lineSpacing(3)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentDirection(of: transcript.text)
                        .padding(Self.transcriptPadding)
                }
                .frame(minHeight: 160, maxHeight: .infinity)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: Metrics.controlSpacing) {
                    anotherFileButton

                    Spacer(minLength: Metrics.controlSpacing)

                    saveButtons
                }

                VStack(alignment: .trailing, spacing: Metrics.controlSpacing) {
                    HStack(spacing: Metrics.controlSpacing) {
                        saveButtons
                    }

                    anotherFileButton
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var anotherFileButton: some View {
        Button("Transcribe Another File", action: model.reset)
            .fixedSize()
    }

    @ViewBuilder
    private var saveButtons: some View {
        Button("Save Text…") { save(.text) }
            .fixedSize()

        Button("Save Subtitles…") { save(.subtitles) }
            .buttonStyle(PushButtonStyle(isProminent: true))
            .fixedSize()
    }

    private func save(_ format: TranscriptFormat) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [format.contentType]
        panel.nameFieldStringValue = file.deletingPathExtension().appendingPathExtension(format.fileExtension).lastPathComponent

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try format.contents(of: transcript).write(to: url, atomically: true, encoding: .utf8)
        } catch {
            NSAlert(error: error).runModal()
        }
    }
}
