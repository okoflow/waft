import Foundation
import Testing
@testable import WaftCore

struct SettingsTests {
    private static let defaults = Settings(languages: LanguageSelection(languages: [.english]))

    @Test
    func `decodes an empty object to the defaults`() throws {
        let settings = try decode("{}")

        #expect(settings == Self.defaults)
        #expect(settings.mode == .light)
        #expect(settings.modelProvider == .cloud(.claude))
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
        #expect(!settings.allowsHandsFree)
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
        var settings = Self.defaults
        settings.mode = .formal
        settings.languages = LanguageSelection(languages: [.english, .ukrainian], pinned: .ukrainian)
        settings.appModes.set(.raw, for: "com.apple.Terminal")
        settings.modelProvider = .localServer
        settings.localServer = LocalServer(baseURL: "http://localhost:1234/v1", model: "qwen")
        settings.instructions.set("Be brief.", for: .clean)
        settings.translation = Translation(target: .german, twoWayLanguage: .english)
        settings.pushToTalkKey = .function
        settings.allowsHandsFree = false
        settings.editKey = PushToTalkKey(keyCode: 96)
        settings.pastesIntoFocusedField = false
        settings.keepsHistory = false
        settings.historyRetention = .forever
        settings.historyLimit = 5000
        settings.playsSounds = false
        settings.showsMenuBarIcon = false
        settings.microphoneID = "usb-mic"
        settings.hasCompletedSetup = true

        let data = try JSONEncoder().encode(settings)

        #expect(try JSONDecoder().decode(Settings.self, from: data) == settings)
    }

    @Test(arguments: [(String?.some("com.apple.Terminal"), Mode.raw), ("com.apple.mail", .formal), (nil, .formal)])
    func `uses the mode set for the app`(bundleIdentifier: String?, expected: Mode) {
        var settings = Self.defaults
        settings.mode = .formal
        settings.appModes.set(.raw, for: "com.apple.Terminal")

        #expect(settings.mode(for: bundleIdentifier) == expected)
    }

    private func decode(_ json: String) throws -> Settings {
        try JSONDecoder().decode(Settings.self, from: Data(json.utf8))
    }
}
