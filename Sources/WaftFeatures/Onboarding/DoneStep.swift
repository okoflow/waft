import SwiftUI
import WaftCore

struct DoneStep: View {
    let model: AppModel

    private var message: LocalizedStringKey {
        guard let shortcutTitle = model.shortcuts.title(for: .modeCycle) else { return "Waft lives in the menu bar." }

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
                        "AI modes",
                        description: "Clean, Formal, and Translate need an AI model.",
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
