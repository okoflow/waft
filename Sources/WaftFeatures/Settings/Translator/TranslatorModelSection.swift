import SwiftUI
import WaftCore

struct TranslatorModelSection: View {
    @Bindable var settings: SettingsModel

    let apiKeys: PerProvider<APIKeyModel>
    let state: SettingsWindowState

    private var setupNote: LocalizedStringKey? {
        AIModelSetup.translator.missingSetup(in: settings, apiKeys: apiKeys)
    }

    var body: some View {
        switch settings.settings.modelProvider {
        case let .cloud(provider):
            section(subtitle: "AI modes keep the model chosen in AI Models.") {
                CloudModelRow(model: $settings.settings.translator.cloudModel, provider: provider)
            }

        case .localServer:
            section {
                SettingsRow("Model", description: "The local server's model, chosen in AI Models.") {
                    if settings.settings.localServer.isConfigured {
                        Text(verbatim: settings.settings.localServer.model)
                            .font(.rowTitle)
                            .foregroundStyle(Palette.secondaryText)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func section(subtitle: LocalizedStringKey? = nil, @ViewBuilder content: () -> some View) -> some View {
        if let setupNote {
            SettingsSection("AI model", subtitle: subtitle, content: content) {
                Text(setupNote)
                    .detailText()

                Button("Set Up…") { state.selection = .aiModels }
            }
        } else {
            SettingsSection("AI model", subtitle: subtitle, content: content)
        }
    }
}
