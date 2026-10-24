import Foundation
import Testing
@testable import WaftCore

struct TranslatorSettingsTests {
    @Test(arguments: [
        (Language?.none, Language.english),
        (.russian, .english),
        (.english, .russian),
    ])
    func `translates the target language into the two-way one`(source: Language?, expected: Language) {
        let settings = TranslatorSettings(translation: Translation(target: .english, twoWayLanguage: .russian))

        #expect(settings.target(forSource: source) == expected)
    }

    @Test(arguments: [
        (Language.english, Language.russian),
        (.russian, .english),
        (.german, .english),
    ])
    func `translates the target language into the chosen source without a two-way language`(
        spoken: Language,
        expected: Language,
    ) {
        var settings = TranslatorSettings()
        settings.source = .russian

        #expect(settings.target(forSource: spoken) == expected)
    }

    @Test
    func `remembers the last three languages, latest first`() {
        var settings = TranslatorSettings()

        for language in [Language.english, .russian, .hebrew, .english, .german] {
            settings.remember(language)
        }

        #expect(settings.recentLanguages == [.german, .english, .hebrew])
    }

    @Test
    func `decodes leniently and keeps at most three recent languages`() throws {
        let json = #"{"source":"xx","cloudModel":"huge","recentLanguages":["de","xx","fr","ja","ko"]}"#

        let settings = try JSONDecoder().decode(TranslatorSettings.self, from: Data(json.utf8))

        #expect(settings.source == nil)
        #expect(settings.cloudModel == .balanced)
        #expect(settings.instructions == TranslatorSettings().instructions)
        #expect(settings.translation == Translation())
        #expect(settings.recentLanguages == [.german, .french, .japanese])
    }

    @Test
    func `drops the old clearer wording flag and keeps the other settings`() throws {
        let json = #"{"source":"de","translation":{"target":"fr"},"rephrases":true,"recentLanguages":["de"]}"#

        let settings = try JSONDecoder().decode(TranslatorSettings.self, from: Data(json.utf8))
        var expected = TranslatorSettings(translation: Translation(target: .french))
        expected.source = .german
        expected.remember(.german)

        #expect(settings == expected)
    }

    @Test(arguments: [
        (Language?.none, Language?.some(.russian)),
        (.russian, .russian),
        (.german, .russian),
        (.english, nil),
        (.ukrainian, nil),
    ])
    func `trusts a chosen source unless the text is in a language of the pair`(detected: Language?, trusted: Language?) {
        var settings = TranslatorSettings(translation: Translation(target: .english, twoWayLanguage: .ukrainian))
        settings.source = .russian

        #expect(settings.trustedSource(detected: detected) == trusted)
    }

    @Test(arguments: [
        (Language.russian, Translation(target: .russian, twoWayLanguage: .english)),
        (.english, Translation(target: .english, twoWayLanguage: .russian)),
        (.german, Translation(target: .german, twoWayLanguage: .russian)),
    ])
    func `swaps the pair and keeps the two-way language for a text outside it`(from: Language, swapped: Translation) {
        let settings = TranslatorSettings(translation: Translation(target: .english, twoWayLanguage: .russian))

        #expect(settings.swapped(from: from) == swapped)
    }
}
