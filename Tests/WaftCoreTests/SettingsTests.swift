import Foundation
import Testing
@testable import WaftCore

struct SettingsTests {
    private static let defaults = Settings(languages: LanguageSelection(languages: [.english]))
    private static let emailReply = CustomMode(name: "Email reply", instructions: "Reply as a short email.")
    private static let unnamed = CustomMode(name: "  ", instructions: " ")

    @Test
    func `decodes an empty object to the defaults`() throws {
        let settings = try decode("{}")

        #expect(settings == Self.defaults)
        #expect(settings.mode == .light)
        #expect(settings.speechModel == .fast)
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
        var settings = Self.defaults
        settings.mode = .formal
        settings.languages = LanguageSelection(languages: [.english, .ukrainian], pinned: .ukrainian)
        settings.speechModel = .accurate
        settings.appModes.set(.raw, for: "com.apple.Terminal")
        settings.modelProvider = .localServer
        settings.localServer = LocalServer(baseURL: "http://localhost:1234/v1", model: "qwen")
        settings.instructions.set("Be brief.", for: .clean)
        settings.translation = Translation(target: .german, twoWayLanguage: .english)
        settings.pushToTalkKey = .function
        settings.dictationStart = .tap
        settings.customModes = [Self.emailReply]
        settings.appModes.set(.custom(Self.emailReply.id), for: "com.apple.mail")
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
        let id = Self.emailReply.id.uuidString
        let settings = try decode(#"""
        {"customModes":[{"id":"\#(id)","name":"Email reply","instructions":"Reply as a short email."},{"name":"Broken"}],
         "mode":"custom:\#(id)","appModes":{"modes":{"com.apple.mail":"custom:\#(id)"}}}
        """#)

        #expect(settings.customModes == [Self.emailReply])
        #expect(settings.mode == .custom(Self.emailReply.id))
        #expect(settings.mode(for: "com.apple.mail") == .custom(Self.emailReply.id))
    }

    @Test
    func `drops modes that point to a missing custom mode`() throws {
        let missing = "custom:\(UUID().uuidString)"
        let settings = try decode(#"{"mode":"\#(missing)","appModes":{"modes":{"com.apple.mail":"\#(missing)","x":"raw"}}}"#)

        #expect(settings.mode == .light)
        #expect(settings.appModes.bundleIdentifiers == ["x"])
    }

    @Test
    func `lists the built-in modes before the custom ones`() {
        var settings = Self.defaults
        settings.customModes = [Self.emailReply]

        #expect(settings.modes == Mode.builtIn + [.custom(Self.emailReply.id)])
    }

    @Test(arguments: [
        (Mode.custom(emailReply.id), "Email reply", "Reply as a short email."),
        (.custom(unnamed.id), "Your mode", "Follows your instructions."),
        (.custom(UUID()), "Your mode", "Follows your instructions."),
        (.formal, "Formal", "Like Clean, in a polite business tone."),
    ])
    func `titles and summarizes a mode`(mode: Mode, title: String, summary: String) {
        var settings = Self.defaults
        settings.customModes = [Self.emailReply, Self.unnamed]

        #expect(settings.title(of: mode) == title)
        #expect(settings.summary(of: mode) == summary)
    }

    @Test(arguments: [
        (true, [Mode.light, .clean, .formal, .translate, .custom(emailReply.id), .raw]),
        (false, [.light, .raw, .light, .light, .light, .light]),
    ])
    func `cycles through the modes`(includingAI: Bool, expected: [Mode]) {
        var settings = Self.defaults
        settings.customModes = [Self.emailReply]

        #expect(settings.modes.map { settings.mode(after: $0, includingAI: includingAI) } == expected)
    }

    @Test
    func `adds, updates, and removes a custom mode`() {
        var settings = Self.defaults
        var custom = settings.addCustomMode(named: "New Mode")
        custom.instructions = "Write haiku."
        settings.update(custom)
        settings.mode = .custom(custom.id)
        settings.appModes.set(.custom(custom.id), for: "com.apple.Notes")

        #expect(settings.customModes == [custom])

        settings.removeCustomMode(custom.id)

        #expect(settings.customModes.isEmpty)
        #expect(settings.mode == .light)
        #expect(settings.appModes.bundleIdentifiers.isEmpty)
    }

    @Test
    func `removes only the custom mode it is asked to remove`() {
        var settings = Self.defaults
        settings.customModes = [Self.unnamed, Self.emailReply]
        settings.mode = .custom(Self.emailReply.id)
        settings.appModes.set(.custom(Self.unnamed.id), for: "com.apple.Notes")
        settings.appModes.set(.custom(Self.emailReply.id), for: "com.apple.mail")

        settings.removeCustomMode(Self.unnamed.id)

        #expect(settings.customModes == [Self.emailReply])
        #expect(settings.mode == .custom(Self.emailReply.id))
        #expect(settings.appModes.bundleIdentifiers == ["com.apple.mail"])
    }

    @Test(arguments: [
        (Mode.custom(emailReply.id), RewritePrompt.customInstructions("Reply as a short email.")),
        (.custom(unnamed.id), RewritePrompt.defaultInstructions(for: .clean)),
        (.custom(UUID()), RewritePrompt.defaultInstructions(for: .clean)),
    ])
    func `rewrites with the instructions of a custom mode`(mode: Mode, instructions: String) {
        var settings = Self.defaults
        settings.customModes = [Self.emailReply, Self.unnamed]

        #expect(settings.rewriteSetup(for: mode).instructions == instructions)
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
