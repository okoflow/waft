import SwiftUI
import WaftCore

struct TranslatorView: View {
    let model: TranslatorModel
    let showPro: () -> Void

    var body: some View {
        VStack(spacing: Metrics.accessorySpacing) {
            if model.isLocked {
                ProGateBanner(
                    title: "The translator is part of Waft+",
                    detail: "Translate and polish text in any of 45 languages with your AI model.",
                    showPro: showPro,
                )
            }

            HStack(spacing: 0) {
                SourcePane(model: model)

                SwapButton(model: model)
                    .frame(width: Metrics.swapButtonSize + Metrics.rowSpacing)

                TranslationPane(model: model)
            }
            .disabled(model.isLocked)
        }
        .padding(.horizontal, Metrics.rowSpacing)
        .padding(.top, Metrics.translatorTop)
        .padding(.bottom, Metrics.rowSpacing)
        .frame(
            minWidth: Metrics.translatorMinimumSize.width,
            maxWidth: .infinity,
            minHeight: Metrics.translatorMinimumSize.height,
            maxHeight: .infinity,
        )
        .windowChrome()
    }
}

private struct SourcePane: View {
    @Bindable var model: TranslatorModel

    @FocusState private var isFocused: Bool

    private var sourceTitle: String {
        guard let language = model.knownSource else { return String(localized: "Detect language") }

        return language.displayName
    }

    private var placeholder: LocalizedStringKey {
        let key = model.dictationKeyTitle

        guard model.startsDictationByTapping else { return "Type, paste, or hold \(key) and speak" }

        return "Type, paste, or tap \(key) and speak"
    }

    private var characterCount: String {
        "\(model.input.count.formatted()) / \(TranslatorModel.characterLimit.formatted())"
    }

    var body: some View {
        TranslatorPane {
            HStack(spacing: Metrics.controlSpacing) {
                LanguagePicker(
                    selection: $model.source,
                    state: model.sourcePicker,
                    title: sourceTitle,
                    label: "Translate from",
                    recent: model.recentLanguages,
                    detectsLanguage: true,
                )

                if model.source == nil, model.detected != nil {
                    Text("detected")
                        .detailText()
                        .transition(.opacity)
                }
            }
            .motion(Motion.fade, value: model.detected)
        } content: {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $model.input)
                    .font(.translatorText)
                    .lineSpacing(Metrics.translatorLineSpacing)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.never)
                    .padding(.horizontal, -Metrics.textInset)
                    .focused($isFocused)
                    .contentDirection(of: model.input)
                    .accessibilityLabel("Text to translate")

                if model.input.isEmpty {
                    Text(placeholder)
                        .font(.translatorText)
                        .foregroundStyle(.tertiary)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
        } footer: {
            Spacer(minLength: Metrics.controlSpacing)

            Text(verbatim: characterCount)
                .detailText()
                .monospacedDigit()
                .accessibilityLabel("\(model.input.count) of \(TranslatorModel.characterLimit) characters")

            if !model.input.isEmpty {
                IconButton(symbolName: "xmark", label: "Clear") {
                    model.clear()
                    isFocused = true
                }
            }
        }
        .onAppear { isFocused = true }
    }
}

private struct TranslationPane: View {
    let model: TranslatorModel

    private var target: Binding<Language?> {
        Binding(
            get: { model.target },
            set: { language in
                guard let language else { return }

                model.target = language
            },
        )
    }

    var body: some View {
        TranslatorPane {
            HStack(spacing: Metrics.controlSpacing) {
                LanguagePicker(
                    selection: target,
                    state: model.targetPicker,
                    title: model.effectiveTarget.displayName,
                    label: "Translate into",
                    recent: model.recentLanguages,
                    detectsLanguage: false,
                )

                if model.isTwoWay {
                    Text("Two-way")
                        .detailText()
                        .transition(.opacity)
                }
            }
            .motion(Motion.fade, value: model.isTwoWay)
        } content: {
            TranslationText(model: model)
        } footer: {
            CopyHint(model: model)
        }
    }
}

private struct TranslationText: View {
    let model: TranslatorModel

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.controlSpacing) {
            if let failure = model.failure {
                Label(failure, systemImage: "exclamationmark.triangle.fill")
                    .font(.rowDetail)
                    .foregroundStyle(Palette.warning)
                    .transition(.opacity)
            }

            if model.isTranslating {
                ShimmeringText(text: model.output.isEmpty ? String(localized: "Translating…") : model.output, color: .primary)
                    .font(.translatorText)
                    .lineSpacing(Metrics.translatorLineSpacing)
                    .contentDirection(of: model.output)
                    .transition(.opacity)
            } else if model.output.isEmpty {
                Text("Translation")
                    .font(.translatorText)
                    .foregroundStyle(.tertiary)
            } else {
                CopyableText(text: model.output, onCopy: model.copy)
                    .accessibilityLabel("Translation")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .motion(Motion.fade, value: model.isTranslating)
        .motion(Motion.fade, value: model.failure)
    }
}

private struct CopyHint: View {
    let model: TranslatorModel

    var body: some View {
        if model.copyFeedback.isShowing(model.output) {
            Label("Copied", systemImage: "checkmark")
                .detailText()
                .transition(.opacity)
        } else if !model.output.isEmpty {
            Text("Click to copy, or select a part")
                .detailText()
                .transition(.opacity)
        }
    }
}

private struct TranslatorPane<Header: View, Content: View, Footer: View>: View {
    @ViewBuilder let header: Header
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.accessorySpacing) {
            header
                .frame(height: Metrics.controlHeight)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            HStack(spacing: Metrics.controlSpacing) {
                footer
            }
            .frame(height: Metrics.controlHeight)
        }
        .padding(Metrics.rowSpacing)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.card, in: RoundedRectangle.card)
    }
}
