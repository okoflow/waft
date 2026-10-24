import Foundation
import Testing
@testable import WaftCore

struct SettingsModesTests {
    private static let unnamed = CustomMode(name: "  ", instructions: " ")

    @Test
    func `lists the built-in modes before the custom ones`() {
        var settings = Settings.defaults
        settings.customModes = [CustomMode.emailReply]

        #expect(settings.modes == Mode.builtIn + [.custom(CustomMode.emailReply.id)])
    }

    @Test(arguments: [
        (Mode.custom(CustomMode.emailReply.id), "Email reply", "Reply as a short email."),
        (.custom(unnamed.id), "Your mode", "Follows your instructions."),
        (.custom(UUID()), "Your mode", "Follows your instructions."),
        (.formal, "Formal", "Like Clean, in a polite business tone."),
    ])
    func `titles and summarizes a mode`(mode: Mode, title: String, summary: String) {
        var settings = Settings.defaults
        settings.customModes = [CustomMode.emailReply, Self.unnamed]

        #expect(settings.title(of: mode) == title)
        #expect(settings.summary(of: mode) == summary)
    }

    @Test(arguments: [
        (true, [Mode.light, .clean, .formal, .translate, .custom(CustomMode.emailReply.id), .raw]),
        (false, [.light, .raw, .light, .light, .light, .light]),
    ])
    func `cycles through the modes`(includingAI: Bool, expected: [Mode]) {
        var settings = Settings.defaults
        settings.customModes = [CustomMode.emailReply]

        #expect(settings.modes.map { settings.mode(after: $0, includingAI: includingAI) } == expected)
    }

    @Test
    func `adds, updates, and removes a custom mode`() {
        var settings = Settings.defaults

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
        var settings = Settings.defaults
        settings.customModes = [Self.unnamed, CustomMode.emailReply]
        settings.mode = .custom(CustomMode.emailReply.id)
        settings.appModes.set(.custom(Self.unnamed.id), for: "com.apple.Notes")
        settings.appModes.set(.custom(CustomMode.emailReply.id), for: "com.apple.mail")

        settings.removeCustomMode(Self.unnamed.id)

        #expect(settings.customModes == [CustomMode.emailReply])
        #expect(settings.mode == .custom(CustomMode.emailReply.id))
        #expect(settings.appModes.bundleIdentifiers == ["com.apple.mail"])
    }

    @Test(arguments: [
        (Mode.custom(CustomMode.emailReply.id), RewritePrompt.customInstructions("Reply as a short email.")),
        (.custom(unnamed.id), RewritePrompt.defaultInstructions(for: .clean)),
        (.custom(UUID()), RewritePrompt.defaultInstructions(for: .clean)),
    ])
    func `rewrites with the instructions of a custom mode`(mode: Mode, instructions: String) {
        var settings = Settings.defaults
        settings.customModes = [CustomMode.emailReply, Self.unnamed]

        #expect(settings.rewriteSetup(for: mode).instructions == instructions)
    }

    @Test(arguments: [(String?.some("com.apple.Terminal"), Mode.raw), ("com.apple.mail", .formal), (nil, .formal)])
    func `uses the mode set for the app`(bundleIdentifier: String?, expected: Mode) {
        var settings = Settings.defaults
        settings.mode = .formal
        settings.appModes.set(.raw, for: "com.apple.Terminal")

        #expect(settings.mode(for: bundleIdentifier) == expected)
    }
}
