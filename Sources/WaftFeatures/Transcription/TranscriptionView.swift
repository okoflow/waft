import AppKit
import SwiftUI
import UniformTypeIdentifiers
import WaftCore

struct TranscriptionView: View {
    let model: FileTranscriptionModel
    let showPro: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.windowSpacing) {
            TranscriptionHeader()

            if model.isLocked {
                VStack(spacing: Metrics.accessorySpacing) {
                    ProGateBanner(showPro: showPro)

                    DropZone(model: model)
                        .disabled(true)
                        .opacity(0.5)
                }
            } else {
                switch model.phase {
                case .idle, .failed:
                    VStack(spacing: Metrics.accessorySpacing) {
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
        .padding(.horizontal, Metrics.windowPadding)
        .padding(.top, Metrics.titleBarHeight)
        .padding(.bottom, Metrics.windowPadding)
        .frame(
            minWidth: Metrics.transcriptionMinimumSize.width,
            maxWidth: .infinity,
            minHeight: Metrics.transcriptionMinimumSize.height,
            maxHeight: .infinity,
            alignment: .top,
        )
        .windowChrome()
        .motion(Motion.layout, value: model.phase)
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
        HStack(spacing: Metrics.accessorySpacing) {
            IconTile(symbolName: "waveform", tint: .red, size: Metrics.headerTileSize)

            VStack(alignment: .leading, spacing: Metrics.labelSpacing) {
                HStack(spacing: Metrics.inlineSpacing) {
                    Text("Transcribe File")
                        .font(.pageTitle)
                        .accessibilityAddTraits(.isHeader)

                    ProBadge()
                }

                Text("Audio and video files, transcribed on this Mac.")
                    .font(.rowDetail)
                    .foregroundStyle(Palette.secondaryText)
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
        let shape = RoundedRectangle.card
        let isTargeted = model.isDropTargeted

        VStack(spacing: Metrics.controlSpacing) {
            Image(systemName: isTargeted ? "arrow.down.doc.fill" : "arrow.down.doc")
                .font(.dropZoneGlyph)
                .foregroundStyle(isTargeted ? Palette.accent : Palette.secondaryText)
                .contentTransition(.symbolEffect(.replace))
                .padding(.bottom, 4)
                .accessibilityHidden(true)

            Text("Drop an audio or video file here")
                .font(.rowTitle)

            Text(hint)
                .font(.rowDetail)
                .foregroundStyle(Palette.secondaryText)

            Button("Choose File…", action: chooseFile)
                .disabled(model.notReadyMessage != nil)
                .padding(.top, Metrics.controlSpacing)
        }
        .frame(maxWidth: .infinity, minHeight: Metrics.dropZoneHeight)
        .background(isTargeted ? Palette.selection : Palette.card, in: shape)
        .overlay {
            shape.strokeBorder(
                isTargeted ? Palette.accent : Palette.dropZoneBorder,
                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]),
            )
        }
        .motion(Motion.fade, value: isTargeted)
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
            HStack(alignment: .top, spacing: Metrics.iconLabelSpacing) {
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

private struct ProGateBanner: View {
    let showPro: () -> Void

    var body: some View {
        let shape = RoundedRectangle.card

        HStack(spacing: Metrics.rowSpacing) {
            WaftPlusMark(size: 20)

            VStack(alignment: .leading, spacing: Metrics.labelSpacing) {
                Text("File transcription is part of Waft+")
                    .font(.cardTitle)

                Text("Recordings and videos become text and subtitles, right on your Mac.")
                    .font(.rowDetail)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button("Unlock Waft+…", action: showPro)
                .buttonStyle(PushButtonStyle(isProminent: true))
        }
        .padding(Metrics.rowPadding)
        .background(Palette.plusTint, in: shape)
    }
}
