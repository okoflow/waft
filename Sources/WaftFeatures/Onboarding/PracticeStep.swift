import SwiftUI
import WaftCore

struct PracticeStep: View {
    @Bindable private var onboarding: OnboardingModel
    @FocusState private var isTyping: Bool

    let model: AppModel

    private var message: LocalizedStringKey {
        let key = model.settings.settings.pushToTalkKey.title

        return switch (model.settings.settings.dictationStart, model.speechModelController.state.isReady) {
        case (.tap, true):
            "Click the box, tap \(key), say “Hello, Waft”, and tap it again."
        case (.tap, false):
            "When the speech model is ready, click the box, tap \(key), say “Hello, Waft”, and tap it again."
        case (.hold, true), (.holdOrDoubleTap, true):
            "Click the box, hold \(key), and say “Hello, Waft”."
        case (.hold, false), (.holdOrDoubleTap, false):
            "When the speech model is ready, click the box, hold \(key), and say “Hello, Waft”."
        }
    }

    private var modelStatus: String {
        let state = model.speechModelController.state

        return state.isReady ? String(localized: "Speech model ready") : state.statusText
    }

    init(model: AppModel) {
        self.model = model
        onboarding = model.onboarding
    }

    var body: some View {
        OnboardingStep(title: "Try it", message: message) {
            IconTile(symbolName: "text.cursor", tint: .purple, size: Metrics.heroTileSize)
        } content: {
            VStack(spacing: Metrics.groupSpacing) {
                TextField("Your words appear here", text: $onboarding.practiceText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.practice)
                    .lineLimit(4, reservesSpace: true)
                    .focused($isTyping)
                    .padding(14)
                    .modifier(FieldChrome(isFocused: isTyping, cornerRadius: Metrics.cardRadius))

                HStack(spacing: Metrics.controlSpacing) {
                    Text(modelStatus)
                        .font(.rowDetail)
                        .foregroundStyle(Palette.secondaryText)

                    if model.speechModelController.state.canRetry {
                        Button("Retry") { model.speechModelController.retry() }
                    }
                }
            }
        }
    }
}
