import SwiftUI
import WaftCore

enum AIModelSetup {
    case modes
    case translator

    private var missingServerNote: LocalizedStringKey {
        switch self {
        case .modes: "AI modes need a local server and model."
        case .translator: "The translator needs a local server and model."
        }
    }

    func missingSetup(in settings: SettingsModel, apiKeys: PerProvider<APIKeyModel>) -> LocalizedStringKey? {
        switch settings.settings.modelProvider {
        case let .cloud(provider):
            apiKeys[provider].isSet
                ? nil
                : missingKeyNote(for: provider)

        case .localServer:
            settings.settings.localServer.isConfigured
                ? nil
                : missingServerNote
        }
    }

    private func missingKeyNote(for provider: CloudProvider) -> LocalizedStringKey {
        switch self {
        case .modes: "AI modes need a \(provider.title) API key."
        case .translator: "The translator needs a \(provider.title) API key."
        }
    }
}
