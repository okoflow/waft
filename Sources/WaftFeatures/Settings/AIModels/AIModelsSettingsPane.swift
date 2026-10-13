import SwiftUI
import WaftCore

struct AIModelsSettingsPane: View {
    @Bindable var settings: SettingsModel

    let speechModel: SpeechModelController
    let apiKeys: PerProvider<APIKeyModel>
    let localModels: LocalModelsModel
    let pro: ProModel
    let state: SettingsWindowState

    var body: some View {
        SpeechModelSection(settings: settings, controller: speechModel, pro: pro, state: state)

        SettingsSection("AI model", subtitle: "Clean, Formal, Translate, and editing by voice use this model.") {
            PickerRow(
                "Provider",
                selection: $settings.settings.modelProvider,
                current: settings.settings.modelProvider.title,
                description: AIModelSetup.missingSetup(in: settings, apiKeys: apiKeys),
            ) {
                Text(ModelProvider.localServer.title).tag(ModelProvider.localServer)
                Divider()
                ForEach(CloudProvider.allCases, id: \.self) { provider in
                    Text(provider.title).tag(ModelProvider.cloud(provider))
                }
            }
        }
        .animation(Motion.layout, value: settings.settings.modelProvider)

        switch settings.settings.modelProvider {
        case .localServer:
            LocalServerSection(settings: settings, localModels: localModels)
        case let .cloud(provider):
            CloudProviderSection(provider: provider, apiKey: apiKeys[provider])
        }
    }
}
