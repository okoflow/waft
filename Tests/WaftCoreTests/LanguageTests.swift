import Testing
@testable import WaftCore

struct LanguageTests {
    @Test(arguments: [
        ("iw", Language?.some(.hebrew)),
        ("he-IL", .hebrew),
        ("nb", .norwegian),
        ("nn-NO", .norwegian),
        ("fil", .filipino),
        ("in", .indonesian),
        ("en-US", .english),
        ("pt_BR", .portuguese),
        ("zh-Hans-CN", .chinese),
        ("sr-Latn", .serbian),
        ("yue", nil),
        ("xx", nil),
        ("", nil),
    ])
    func `reads the language of a locale identifier`(identifier: String, expected: Language?) {
        #expect(Language(localeIdentifier: identifier) == expected)
    }

    @Test(arguments: [(Language.filipino, "fil"), (.hebrew, "he"), (.norwegian, "no"), (.english, "en")])
    func `knows the locale code of a language`(language: Language, code: String) {
        #expect(language.localeCode == code)
    }

    @Test(arguments: [
        ([Language.english, .russian, .ukrainian], [Language.russian, .ukrainian]),
        ([.serbian, .bosnian, .german], [.serbian, .bosnian]),
        ([.english, .german], []),
    ])
    func `finds languages that sound alike`(languages: [Language], expected: [Language]) {
        #expect(Language.soundAlike(among: languages) == expected)
    }

    @Test(arguments: [
        (Language.english, ".", true, true),
        (.japanese, "。", false, false),
        (.chinese, "。", false, false),
        (.thai, "", false, false),
        (.korean, ".", true, false),
        (.hindi, "।", true, false),
        (.russian, ".", true, true),
    ])
    func `knows the typography of a language`(language: Language, fullStop: String, spaced: Bool, hasCase: Bool) {
        #expect(language.fullStop == fullStop)
        #expect(language.separatesWordsWithSpaces == spaced)
        #expect(language.hasLetterCase == hasCase)
    }

    @Test(arguments: [(Language.english, " "), (.japanese, ""), (.chinese, ""), (.thai, ""), (.korean, " ")])
    func `puts a space between words only where the script does`(language: Language, separator: String) {
        #expect(language.wordSeparator == separator)
    }

    @Test(arguments: [
        (Language.chinese, [WritingVariant.simplified, .traditional]),
        (.serbian, [.latin, .cyrillic]),
        (.english, []),
    ])
    func `offers a choice of script only for Chinese and Serbian`(language: Language, variants: [WritingVariant]) {
        #expect(language.writingVariants == variants)
    }
}
