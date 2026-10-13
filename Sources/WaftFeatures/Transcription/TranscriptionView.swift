import AppKit
import SwiftUI
import UniformTypeIdentifiers
import WaftCore

struct TranscriptionView: View {
    let model: FileTranscriptionModel
    let showPro: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            TranscriptionHeader()

            if model.isLocked {
                ProGateCard(showPro: showPro)
            } else {
                switch model.phase {
                case .idle, .failed:
                    VStack(spacing: 12) {
                        if case let .failed(file, message) = model.phase {
                            FailureCard(file: file, message: message)
                                .transition(.reveal)
                        }

                        DropZone(model: model)
                        LanguageCard(model: model)
                    }
                    .transition(.opacity)

                case let .reading(file), let .transcribing(file, _):
                    ProgressCard(model: model, file: file)
                        .transition(.opacity)

                case let .finished(file, transcript):
                    ResultView(model: model, file: file, transcript: transcript)
                        .transition(.opacity)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 52)
        .padding(.bottom, 24)
        .frame(minWidth: 520, maxWidth: .infinity, minHeight: 480, maxHeight: .infinity, alignment: .top)
        .background(Palette.window)
        .ignoresSafeArea()
        .buttonStyle(PushButtonStyle())
        .animation(Motion.layout, value: model.phase)
        .reducedMotionPolicy()
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first, model.acceptsFiles else { return false }

            model.transcribe(url)

            return true
        } isTargeted: { isTargeted in
            model.isDropTargeted = isTargeted
        }
    }
}

private struct TranscriptionHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            IconTile(symbolName: "waveform", tint: .purple, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("Transcribe File")
                    .font(.pageTitle)

                Text("Audio and video files, transcribed on this Mac.")
                    .font(.rowDetail)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct DropZone: View {
    private static let mediaTypes: [UTType] = [.audio, .movie, .audiovisualContent]

    let model: FileTranscriptionModel

    private var hint: LocalizedStringKey {
        guard let message = model.notReadyMessage else { return "MP3, M4A, WAV, MP4, MOV, and more" }

        return .verbatim(message)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
        let isTargeted = model.isDropTargeted

        VStack(spacing: 8) {
            Image(systemName: isTargeted ? "arrow.down.doc.fill" : "arrow.down.doc")
                .font(.system(size: 30))
                .foregroundStyle(isTargeted ? Color.accentColor : .secondary)
                .contentTransition(.symbolEffect(.replace))
                .padding(.bottom, 4)
                .accessibilityHidden(true)

            Text("Drop an audio or video file here")
                .font(.rowTitle)

            Text(hint)
                .font(.rowDetail)
                .foregroundStyle(.secondary)

            Button("Choose File…", action: chooseFile)
                .disabled(model.notReadyMessage != nil)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .background(isTargeted ? Palette.selection : Palette.card, in: shape)
        .overlay {
            shape.strokeBorder(
                isTargeted ? Color.accentColor : Palette.dropZoneBorder,
                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]),
            )
        }
        .animation(Motion.fade, value: isTargeted)
    }

    private func chooseFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = Self.mediaTypes
        panel.allowsMultipleSelection = false
        panel.prompt = String(localized: "Transcribe")

        guard panel.runModal() == .OK, let url = panel.url else { return }

        model.transcribe(url)
    }
}

private struct LanguageCard: View {
    @Bindable var model: FileTranscriptionModel

    private var languageTitle: String {
        guard let language = model.language else { return String(localized: "Automatic") }

        return language.displayName
    }

    var body: some View {
        SettingsCard {
            PickerRow(
                "Language",
                selection: $model.language,
                current: languageTitle,
                description: "The languages you chose in Settings › Dictation.",
            ) {
                Text("Automatic").tag(Language?.none)

                ForEach(model.languages, id: \.self) { language in
                    Text(language.displayName).tag(Language?.some(language))
                }
            }
        }
    }
}

private struct FailureCard: View {
    let file: URL
    let message: String

    var body: some View {
        SettingsCard {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Palette.warning)
                    .accessibilityHidden(true)

                RowLabel(title: "Couldn't transcribe \(file.lastPathComponent)", description: .verbatim(message))

                Spacer(minLength: 0)
            }
            .settingsRowPadding()
        }
    }
}

private struct ProGateCard: View {
    let showPro: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)

        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 24))
                .padding(.bottom, 4)
                .accessibilityHidden(true)

            Text("File transcription is part of Waft Pro")
                .font(.sectionTitle)

            Text("Recordings and videos become text and subtitles, right on your Mac.")
                .font(.rowDetail)
                .opacity(0.9)

            Button("Unlock Waft Pro…", action: showPro)
                .buttonStyle(ProButtonStyle())
                .padding(.top, 10)
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 220)
        .background(Palette.proGradient, in: shape)
    }
}
