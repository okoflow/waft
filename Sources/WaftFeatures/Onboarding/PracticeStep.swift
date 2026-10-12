import SwiftUI
import WaftCore

struct PracticeStep: View {
    @Bindable private var onboarding: OnboardingModel
    @FocusState private var isTyping: Bool

    let model: AppModel

    private var message: LocalizedStringKey {
        let key = model.settings.settings.pushToTalkKey.title

        guard model.speechModel.state.isReady else {
            return "When the speech model is ready, click the box, hold \(key), and say “Hello, Waft”."
        }

        return "Click the box, hold \(key), and say “Hello, Waft”."
    }

    private var modelStatus: String {
        model.speechModel.state.isReady ? String(localized: "Speech model ready") : model.speechModel.state.statusText
    }

    init(model: AppModel) {
        self.model = model
        onboarding = model.onboarding
    }

    var body: some View {
        OnboardingStep(title: "Try it", message: message) {
            IconTile(symbolName: "text.cursor", tint: .purple, size: Metrics.heroTileSize)
        } content: {
            VStack(spacing: 10) {
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
                        .foregroundStyle(.secondary)

                    if model.speechModel.state.canRetry {
                        Button("Retry") { model.speechModel.retry() }
                    }
                }
            }
        }
    }
}
