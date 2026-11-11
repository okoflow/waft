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

    func missingSetup(in settings: SettingsModel, apiKeys: PerProvider<APIKeyModel>, pro: ProModel) -> LocalizedStringKey? {
        guard pro.isUnlocked else { return nil }

        switch settings.settings.modelProvider {
        case .localServer:
            guard !settings.settings.localServer.isConfigured else { return nil }

            return missingServerNote

        case let .cloud(provider):
            guard !apiKeys[provider].isSet else { return nil }

            return missingKeyNote(for: provider)
        }
    }

    private func missingKeyNote(for provider: CloudProvider) -> LocalizedStringKey {
        switch self {
        case .modes: "AI modes need a \(provider.title) API key."
        case .translator: "The translator needs a \(provider.title) API key."
        }
    }
}
