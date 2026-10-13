import AppKit
import SwiftUI
import WaftCore

struct AIModelsSettingsPane: View {
    @Bindable var settings: SettingsModel

    let speechModel: SpeechModelController
    let apiKeys: PerProvider<APIKeyModel>
    let localModels: LocalModelsModel

    var body: some View {
        SettingsSection("Speech recognition", subtitle: "Whisper runs on this Mac, so audio never leaves it.") {
            SpeechModelRow(controller: speechModel)
        }

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

private struct SpeechModelRow: View {
    let controller: SpeechModelController

    var body: some View {
        SettingsRow(.verbatim("Whisper large-v3 turbo · 630 MB"), description: .verbatim(controller.state.statusText)) {
            if let progress = controller.state.progress {
                ProgressView(value: progress)
                    .frame(width: 100)
            }

            if controller.state.canRetry {
                Button("Retry") { controller.retry() }
            }

            Button("Show in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([controller.modelDirectory])
            }
        }
    }
}
