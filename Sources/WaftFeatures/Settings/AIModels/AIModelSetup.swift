import SwiftUI
import WaftCore

enum AIModelSetup {
    static func missingSetup(in settings: SettingsModel, apiKeys: PerProvider<APIKeyModel>) -> LocalizedStringKey? {
        switch settings.settings.modelProvider {
        case let .cloud(provider):
            apiKeys[provider].isSet ? nil : "Clean, Formal, and Translate need a \(provider.title) API key."
        case .localServer:
            settings.settings.localServer.isConfigured ? nil : "Clean, Formal, and Translate need a local server and model."
        }
    }
}
