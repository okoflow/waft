import SwiftUI
import WaftCore

struct TranslatorModelSection: View {
    @Bindable var settings: SettingsModel

    let state: SettingsWindowState

    private var model: CloudModel {
        settings.settings.translator.cloudModel
    }

    var body: some View {
        switch settings.settings.modelProvider {
        case let .cloud(provider):
            SettingsSection("AI model", subtitle: "AI modes keep the model chosen in AI Models.", isPro: true) {
                PickerRow(
                    "Model",
                    selection: $settings.settings.translator.cloudModel,
                    current: provider.name(of: model),
                    description: .verbatim(model.summary),
                ) {
                    ForEach(CloudModel.allCases, id: \.self) { model in
                        Text(verbatim: provider.name(of: model)).tag(model)
                    }
                }
            }

        case .localServer:
            SettingsSection("AI model", isPro: true) {
                SettingsRow("Model", description: "The local server's model, chosen in AI Models.") {
                    Button("Set Up…") { state.selection = .aiModels }
                }
            }
        }
    }
}
