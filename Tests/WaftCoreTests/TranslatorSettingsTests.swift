import Foundation
import Testing
import WaftCore

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
        let json = #"{"source":"xx","rephrases":true,"recentLanguages":["de","xx","fr","ja","ko"]}"#
        let settings = try JSONDecoder().decode(TranslatorSettings.self, from: Data(json.utf8))

        #expect(settings.source == nil)
        #expect(settings.rephrases)
        #expect(settings.translation == Translation())
        #expect(settings.recentLanguages == [.german, .french, .japanese])
    }
}
