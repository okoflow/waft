import SwiftUI
import Testing
import WaftCore
@testable import WaftFeatures

struct AIModelSetupTests {
    private let settings = SettingsModel.inMemory()

    @Test(arguments: [
        (AIModelSetup.modes, CloudProvider.claude, false),
        (.modes, .openAI, true),
        (.translator, .openAI, false),
        (.translator, .claude, true),
    ])
    func `asks for the API key of the chosen cloud provider until it is saved`(
        setup: AIModelSetup,
        provider: CloudProvider,
        hasKey: Bool,
    ) {
        settings.settings.modelProvider = .cloud(provider)
        let apiKeys = PerProvider { cloudProvider in
            APIKeyModel(store: FakeValueStore(cloudProvider == provider ? keyIfSaved(hasKey) : nil))
        }

        #expect((setup.missingSetup(in: settings, apiKeys: apiKeys) == nil) == hasKey)
    }

    @Test(arguments: [
        (AIModelSetup.modes, "", String?.some("AI modes need a local server and model.")),
        (.translator, "", "The translator needs a local server and model."),
        (.modes, "qwen3", nil),
        (.translator, "qwen3", nil),
    ])
    func `asks for a local server and model until both are set`(setup: AIModelSetup, model: String, note: String?) {
        settings.settings.modelProvider = .localServer
        settings.settings.localServer = LocalServer(model: model)

        let apiKeys = PerProvider { _ in APIKeyModel(store: FakeValueStore<String>()) }

        #expect(setup.missingSetup(in: settings, apiKeys: apiKeys) == note.map { LocalizedStringKey($0) })
    }

    private func keyIfSaved(_ hasKey: Bool) -> String? {
        guard hasKey else { return nil }

        return "saved-key"
    }
}
