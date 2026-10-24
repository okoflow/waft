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
            guard !apiKeys[provider].isSet else { return nil }

            return missingKeyNote(for: provider)

        case .localServer:
            guard !settings.settings.localServer.isConfigured else { return nil }

            return missingServerNote
        }
    }

    private func missingKeyNote(for provider: CloudProvider) -> LocalizedStringKey {
        switch self {
        case .modes: "AI modes need a \(provider.title) API key."
        case .translator: "The translator needs a \(provider.title) API key."
        }
    }
}
