import SwiftUI

struct DoneStep: View {
    let model: AppModel

    private var message: LocalizedStringKey {
        guard let shortcutTitle = model.modeSwitcher.shortcutTitle else { return "Waft lives in the menu bar." }

        return "Waft lives in the menu bar. \(shortcutTitle) switches to the next mode."
    }

    private var needsAIModel: Bool {
        AIModelSetup.missingSetup(in: model.settings, apiKeys: model.apiKeys) != nil
    }

    var body: some View {
        OnboardingStep(title: "You're all set", message: message) {
            IconTile(symbolName: "checkmark", tint: .green, size: Metrics.heroTileSize)
        } content: {
            SettingsCard {
                ToggleRow("Open at login", isOn: Bindable(model.settings).launchesAtLogin)

                if needsAIModel {
                    RowDivider()
                    SettingsRow(
                        "Cleanup modes",
                        description: "Clean, Formal, and Translate need an AI model, on this Mac or in the cloud.",
                    ) {
                        Button("Set Up…") {
                            model.onboarding.finish()
                            model.windows.showSettings(.aiModels)
                        }
                    }
                }
            }
        }
    }
}
