import Testing
@testable import WaftCore

struct LightModeRulesTests {
    @Test(arguments: [
        ("um so i think, uh, we should go", Language.english, "So i think we should go."),
        ("Ummm, hello there", .english, "Hello there."),
        ("we should go, um.", .english, "We should go."),
        ("I agree. Um, so what?", .english, "I agree. So what?"),
        ("hmm, let me think", .english, "Let me think."),
        ("call me at 5, uh, tomorrow", .english, "Call me at 5 tomorrow."),
        ("first line\num, second line", .english, "First line\nsecond line."),
        ("э, ну, давай начнём", .russian, "Ну, давай начнём."),
        ("э-э, привет", .russian, "Привет."),
        ("это, мм, хорошо", .russian, "Это хорошо."),
        ("äh, ich weiß nicht, ähm, vielleicht", .german, "Ich weiß nicht vielleicht."),
        ("我们，嗯，走吧", .chinese, "我们走吧。"),
        ("今日は、えーと、晴れです", .japanese, "今日は晴れです。"),
    ])
    func `removes hesitations`(text: String, language: Language, expected: String) {
        #expect(LightModeRules.apply(text, language: language) == expected)
    }

    @Test
    func `keeps a unit after a number that is spelled like a hesitation`() {
        #expect(LightModeRules.apply("длина 5 мм", language: .russian) == "Длина 5 мм.")
    }

    @Test(arguments: [
        ("hello  ,  world", "Hello, world."),
        ("hello ! how are you ?", "Hello! how are you?"),
        ("wait ; no : yes", "Wait; no: yes."),
        ("  spaced    out\twords  ", "Spaced out words."),
        ("first line \n second line", "First line\nsecond line."),
        ("and so on...", "And so on…"),
        ("it costs 5", "It costs 5."),
        ("(see above)", "(See above)"),
    ])
    func `tidies English spacing and adds a full stop`(text: String, expected: String) {
        #expect(LightModeRules.apply(text, language: .english) == expected)
    }

    @Test(arguments: [
        ("bonjour ! ça va ?", "Bonjour ! ça va ?"),
        ("attendez ; voilà : fini", "Attendez ; voilà : fini."),
        ("euh, d'accord , merci", "D'accord, merci."),
    ])
    func `keeps French spaces before high punctuation`(text: String, expected: String) {
        #expect(LightModeRules.apply(text, language: .french) == expected)
    }

    @Test(arguments: [
        ("えーと、今日は晴れです", Language.japanese, "今日は晴れです。"),
        ("嗯，我们走吧", .chinese, "我们走吧。"),
        ("我们走吧。", .chinese, "我们走吧。"),
        ("नमस्ते दोस्तों", .hindi, "नमस्ते दोस्तों।"),
        ("สวัสดีครับ", .thai, "สวัสดีครับ"),
    ])
    func `ends sentences with the full stop of the language`(text: String, language: Language, expected: String) {
        #expect(LightModeRules.apply(text, language: language) == expected)
    }

    @Test(arguments: [(Language.turkish, "İstanbul güzel."), (.english, "Istanbul güzel.")])
    func `capitalizes a leading i by the rules of the language`(language: Language, expected: String) {
        #expect(LightModeRules.apply("istanbul güzel", language: language) == expected)
    }

    @Test(arguments: [("τι κάνεις; εε, καλά", Language.greek, "Τι κάνεις; Καλά."), ("wait; um, fine", .english, "Wait; fine.")])
    func `capitalizes after the question mark of the language`(text: String, language: Language, expected: String) {
        #expect(LightModeRules.apply(text, language: language) == expected)
    }

    @Test(arguments: [
        ("umbrella, um, open", Language.english, "Umbrella open."),
        ("uh-uh, no", .english, "Uh-uh, no."),
        ("Эммм, да", .russian, "Да."),
        ("um, hello", .japanese, "um, hello。"),
    ])
    func `recognizes hesitations by the rules of the language`(text: String, language: Language, expected: String) {
        #expect(LightModeRules.apply(text, language: language) == expected)
    }

    @Test
    func `leaves only hesitations as empty text`() {
        #expect(LightModeRules.apply("um, uh", language: .english).isEmpty)
    }
}
