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

        #expect((setup.missingSetup(in: settings, apiKeys: apiKeys, pro: .unlicensed()) == nil) == hasKey)
    }

    @Test(arguments: [
        (AIModelSetup.modes, "", String?.some("AI modes need a local server and model.")),
        (.translator, "", "The translator needs a local server and model."),
        (.modes, "qwen3", nil),
    ])
    func `asks for a local server and model until both are set`(setup: AIModelSetup, model: String, note: String?) {
        settings.settings.modelProvider = .localServer
        settings.settings.localServer = LocalServer(model: model)

        let apiKeys = PerProvider { _ in APIKeyModel(store: FakeValueStore<String>()) }

        #expect(setup.missingSetup(in: settings, apiKeys: apiKeys, pro: .unlicensed()) == note.map { LocalizedStringKey($0) })
    }

    @Test(arguments: [
        (AIModelSetup.modes, ModelProvider.cloud(.claude)),
        (.translator, .cloud(.openAI)),
        (.modes, .localServer),
        (.translator, .localServer),
    ])
    func `asks for no setup while Waft+ is locked`(setup: AIModelSetup, provider: ModelProvider) {
        settings.settings.modelProvider = provider

        let apiKeys = PerProvider { _ in APIKeyModel(store: FakeValueStore<String>()) }
        let pro = ProModel.unlicensed(trialStarted: .distantPast)

        #expect(setup.missingSetup(in: settings, apiKeys: apiKeys, pro: pro) == nil)
    }

    private func keyIfSaved(_ hasKey: Bool) -> String? {
        guard hasKey else { return nil }

        return "saved-key"
    }
}
