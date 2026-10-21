import SwiftUI
import WaftCore

struct TranslatorModelSection: View {
    @Bindable var settings: SettingsModel

    let state: SettingsWindowState

    var body: some View {
        switch settings.settings.modelProvider {
        case let .cloud(provider):
            SettingsSection("AI model", subtitle: "AI modes keep the model chosen in AI Models.") {
                CloudModelRow(model: $settings.settings.translator.cloudModel, provider: provider)
            }

        case .localServer:
            SettingsSection("AI model") {
                SettingsRow("Model", description: "The local server's model, chosen in AI Models.") {
                    Button("Set Up…") { state.selection = .aiModels }
                }
            }
        }
    }
}
