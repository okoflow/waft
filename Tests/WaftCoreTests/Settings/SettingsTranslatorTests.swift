import Testing
@testable import WaftCore

struct SettingsTranslatorTests {
    @Test(arguments: [
        (CloudProvider.claude, CloudModel.fastest, Duration.seconds(20)),
        (.openAI, .smartest, .seconds(45)),
    ])
    func `uses the model of the translator for the cloud provider`(
        provider: CloudProvider,
        model: CloudModel,
        deadline: Duration,
    ) {
        var settings = Settings.defaults
        settings.modelProvider = .cloud(provider)
        settings.cloudModels = PerProvider(claude: .smartest, openAI: .fastest)
        settings.translator.cloudModel = model

        let setup = settings.translatorSetup(for: .translate)

        #expect(setup.cloudModelInUse == model)
        #expect(setup.editDeadline == deadline)
        #expect(setup.serverInUse == nil)
    }

    @Test
    func `keeps the model of the local server`() {
        var settings = Settings.defaults
        settings.modelProvider = .localServer
        settings.localServer = LocalServer(baseURL: "http://localhost:11434/v1", model: "qwen")
        settings.translator.cloudModel = .smartest

        let setup = settings.translatorSetup(for: .fix)

        #expect(setup.serverInUse == settings.localServer)
        #expect(setup.cloudModelInUse == nil)
    }

    @Test(arguments: TextTask.Kind.allCases)
    func `uses the instructions of the translator for the task`(kind: TextTask.Kind) {
        var settings = Settings.defaults

        #expect(settings.translatorSetup(for: kind).instructions == RewritePrompt.defaultTextInstructions(for: kind))

        settings.translator.instructions.set("Keep it short.", for: kind)

        #expect(settings.translatorSetup(for: kind).instructions == "Keep it short.")
    }

    @Test(arguments: [
        (["ru-RU", "en-US"], Language?.some(.russian)),
        (["en-GB", "de-DE"], .german),
        (["en-US"], nil),
    ])
    func `pairs English with the first other system language for a new translator`(
        localeIdentifiers: [String],
        otherLanguage: Language?,
    ) {
        let settings = Settings(preferredLanguages: localeIdentifiers)

        #expect(settings.translator.source == nil)
        #expect(settings.translator.translation == Translation(target: .english, twoWayLanguage: otherLanguage))
        #expect(settings.translation == Translation())
    }

    @Test
    func `expects the translator's languages, then the dictation and recent ones, each once`() {
        var settings = Settings(languages: LanguageSelection(languages: [.english, .german]))
        settings.translator.translation = Translation(target: .english, twoWayLanguage: .russian)
        settings.translator.remember(.french)
        settings.translator.remember(.russian)

        #expect(settings.expectedTranslatorLanguages == [.russian, .english, .german, .french])
        #expect(settings.translatorDetectionHints == settings.expectedTranslatorLanguages)

        settings.translator.source = .ukrainian

        #expect(settings.expectedTranslatorLanguages.first == .ukrainian)
        #expect(settings.translatorDetectionHints == [.ukrainian])
    }
}
