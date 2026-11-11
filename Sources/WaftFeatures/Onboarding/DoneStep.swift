import SwiftUI
import WaftCore

struct DoneStep: View {
    let model: AppModel

    private var message: LocalizedStringKey {
        guard let shortcutTitle = model.shortcuts.title(for: .modeCycle) else { return "Waft lives in the menu bar." }

        return "Waft lives in the menu bar. \(shortcutTitle) switches to the next mode."
    }

    private var needsAIModel: Bool {
        AIModelSetup.modes.missingSetup(in: model.settings, apiKeys: model.apiKeys, pro: model.pro) != nil
    }

    var body: some View {
        OnboardingStep(title: "You're all set", message: message) {
            IconTile(symbolName: "checkmark", tint: .green, size: Metrics.heroTileSize)
        } content: {
            VStack(spacing: Metrics.groupSpacing) {
                SettingsCard {
                    ToggleRow("Open at login", isOn: Bindable(model.settings).launchesAtLogin)

                    if needsAIModel {
                        RowDivider()

                        SettingsRow(
                            "AI modes",
                            description: "Clean, Formal, and Translate need an AI model.",
                        ) {
                            Button("Set Up…") { finish(showing: .aiModels) }
                        }
                    }
                }

                if let trialOffer = model.pro.trialOffer {
                    Text(trialOffer)
                        .detailText()
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Metrics.rowPadding)
                }

                if !model.pro.isUnlocked {
                    ProGateBanner.aiModes { finish(showing: .pro) }
                }
            }
        }
    }

    private func finish(showing pane: SettingsPane) {
        model.onboarding.finish()
        model.showSettings(pane)
    }
}
