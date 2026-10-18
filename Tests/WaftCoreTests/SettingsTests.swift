import Foundation
import Testing
@testable import WaftCore

struct SettingsTests {
    @Test
    func `decodes an empty object to the defaults`() throws {
        let settings = try decode("{}")

        #expect(settings == Settings.defaults)
        #expect(settings.mode == .light)
        #expect(settings.speechModel == .fast)
        #expect(settings.modelProvider == .cloud(.claude))
        #expect(settings.cloudModels == PerProvider(claude: .balanced, openAI: .balanced))
        #expect(settings.pushToTalkKey == .rightOption)
        #expect(settings.historyLimit == DictationHistory.defaultLimit)
        #expect(settings.editKey == nil)
    }

    @Test
    func `replaces an unknown mode and keeps the other fields`() throws {
        let settings = try decode(#"{"mode":"bogus","playsSounds":false,"keepsHistory":false}"#)

        #expect(settings.mode == .light)
        #expect(!settings.playsSounds)
        #expect(!settings.keepsHistory)
    }

    @Test(arguments: [(7, 1000), (500, 500), (10000, 10000), (-1, 1000)])
    func `accepts only the offered history limits`(stored: Int, expected: Int) throws {
        #expect(try decode(#"{"historyLimit":\#(stored)}"#).historyLimit == expected)
    }

    @Test
    func `replaces an unsupported push-to-talk key and keeps the other fields`() throws {
        let settings = try decode(#"{"pushToTalkKey":9999,"handsFreeDoubleTap":false,"editKey":9999,"microphoneID":"usb-mic"}"#)

        #expect(settings.pushToTalkKey == .rightOption)
        #expect(settings.dictationStart == .hold)
        #expect(settings.editKey == nil)
        #expect(settings.microphoneID == "usb-mic")
    }

    @Test(arguments: [
        ("local", ModelProvider.localServer),
        ("openai", .cloud(.openAI)),
        ("claude", .cloud(.claude)),
        ("gemini", .cloud(.claude)),
    ])
    func `decodes the model provider`(stored: String, expected: ModelProvider) throws {
        #expect(try decode(#"{"modelProvider":"\#(stored)"}"#).modelProvider == expected)
    }

    @Test(arguments: [
        (#"{"claude":"smartest","openAI":"fastest"}"#, PerProvider(claude: CloudModel.smartest, openAI: .fastest)),
        (#"{"claude":"huge","openAI":"fastest"}"#, PerProvider(claude: .balanced, openAI: .balanced)),
        (#"{"claude":"fastest"}"#, PerProvider(claude: .balanced, openAI: .balanced)),
    ])
    func `decodes the cloud models`(stored: String, expected: PerProvider<CloudModel>) throws {
        #expect(try decode(#"{"cloudModels":\#(stored)}"#).cloudModels == expected)
    }

    @Test(arguments: [("fast", SpeechModel.fast), ("accurate", .accurate), ("huge", .fast)])
    func `decodes the speech model`(stored: String, expected: SpeechModel) throws {
        #expect(try decode(#"{"speechModel":"\#(stored)"}"#).speechModel == expected)
    }

    @Test
    func `decodes nested values leniently`() throws {
        let json = #"""
        {"languages":{"languages":["ru","de"],"pinned":"de"},"localServer":{"model":"qwen"},"historyRetention":"never",
         "translation":{"target":"fr"},"editKey":122,"mode":"translate"}
        """#

        let settings = try decode(json)

        #expect(settings.languages.languages == [.german, .russian])
        #expect(settings.languages.pinned == .german)
        #expect(settings.localServer == LocalServer(model: "qwen"))
        #expect(settings.historyRetention == .month)
        #expect(settings.translation == Translation(target: .french))
        #expect(settings.editKey == PushToTalkKey(keyCode: 122))
        #expect(settings.mode == .translate)
    }

    @Test
    func `survives an encoding round trip`() throws {
        var settings = Settings.defaults
        settings.mode = .formal
        settings.languages = LanguageSelection(languages: [.english, .ukrainian], pinned: .ukrainian)
        settings.writingVariants = WritingVariants().choosing(.cyrillic, for: .serbian)
        settings.speechModel = .accurate
        settings.appModes.set(.raw, for: "com.apple.Terminal")
        settings.modelProvider = .localServer
        settings.cloudModels[.openAI] = .smartest
        settings.localServer = LocalServer(baseURL: "http://localhost:1234/v1", model: "qwen")
        settings.instructions.set("Be brief.", for: .clean)
        settings.translation = Translation(target: .german, twoWayLanguage: .english)
        settings.pushToTalkKey = .function
        settings.dictationStart = .tap
        settings.customModes = [CustomMode.emailReply]
        settings.appModes.set(.custom(CustomMode.emailReply.id), for: "com.apple.mail")
        settings.editKey = PushToTalkKey(keyCode: 96)
        settings.pastesIntoFocusedField = false
        settings.keepsHistory = false
        settings.historyRetention = .forever
        settings.historyLimit = 5000
        settings.playsSounds = false
        settings.lowersOtherSounds = false
        settings.showsMenuBarIcon = false
        settings.microphoneID = "usb-mic"
        settings.hasCompletedSetup = true

        #expect(try JSONDecoder().decode(Settings.self, from: JSONEncoder().encode(settings)) == settings)
    }

    @Test(arguments: [
        (#"{}"#, DictationStart.holdOrDoubleTap),
        (#"{"handsFreeDoubleTap":false}"#, .hold),
        (#"{"handsFreeDoubleTap":false,"dictationStart":"tap"}"#, .tap),
        (#"{"dictationStart":"hold"}"#, .hold),
        (#"{"handsFreeDoubleTap":false,"dictationStart":"holdOrDoubleTap"}"#, .holdOrDoubleTap),
        (#"{"dictationStart":"bogus"}"#, .holdOrDoubleTap),
    ])
    func `decodes how dictation starts from the earlier double-tap setting`(json: String, expected: DictationStart) throws {
        #expect(try decode(json).dictationStart == expected)
    }

    @Test
    func `decodes the stored custom modes and keeps the modes that point to them`() throws {
        let id = CustomMode.emailReply.id.uuidString

        let settings = try decode(#"""
        {"customModes":[{"id":"\#(id)","name":"Email reply","instructions":"Reply as a short email."},{"name":"Broken"}],
         "mode":"custom:\#(id)","appModes":{"modes":{"com.apple.mail":"custom:\#(id)"}}}
        """#)

        #expect(settings.customModes == [CustomMode.emailReply])
        #expect(settings.mode == .custom(CustomMode.emailReply.id))
        #expect(settings.mode(for: "com.apple.mail") == .custom(CustomMode.emailReply.id))
    }

    @Test
    func `drops modes that point to a missing custom mode`() throws {
        let missing = "custom:\(UUID().uuidString)"

        let settings = try decode(#"{"mode":"\#(missing)","appModes":{"modes":{"com.apple.mail":"\#(missing)","x":"raw"}}}"#)

        #expect(settings.mode == .light)
        #expect(settings.appModes.bundleIdentifiers == ["x"])
    }

    private func decode(_ json: String) throws -> Settings {
        try JSONDecoder().decode(Settings.self, from: Data(json.utf8))
    }
}
