import Foundation
import Testing
@testable import WaftCore

struct LanguageSelectionTests {
    @Test(arguments: [
        ([Language.russian, .english, .russian], [Language.english, .russian]),
        ([.ukrainian, .german, .arabic], [.arabic, .german, .ukrainian]),
        ([], [.english]),
    ])
    func `orders languages and keeps at least one`(languages: [Language], expected: [Language]) {
        #expect(LanguageSelection(languages: languages).languages == expected)
    }

    @Test(arguments: [
        ([Language.english], Language?.none, Language?.some(.english)),
        ([.english, .german], nil, nil),
        ([.english, .german], .german, .german),
    ])
    func `forces a language when one is pinned or only one is enabled`(
        languages: [Language],
        pinned: Language?,
        expected: Language?,
    ) {
        #expect(LanguageSelection(languages: languages, pinned: pinned).forcedLanguage == expected)
    }

    @Test(arguments: [
        (["ru-RU", "de-DE"], [Language.english, .german, .russian]),
        (["en-US", "ru-RU", "de", "fr", "es"], [.english, .german, .russian]),
        (["fr-FR", "de", "es", "ru"], [.english, .french, .german, .spanish]),
        (["xx", "en-GB", "en-US"], [.english]),
        (["uk-UA", "uk"], [.english, .ukrainian]),
        ([], [.english]),
    ])
    func `prefers the first three system languages and English`(identifiers: [String], expected: [Language]) {
        #expect(LanguageSelection.preferred(by: identifiers).languages == expected)
    }

    @Test
    func `adds and removes languages`() {
        let selection = LanguageSelection(languages: [.english]).adding(.german)

        #expect(selection.languages == [.english, .german])
        #expect(selection.removing(.english).languages == [.german])
    }

    @Test
    func `keeps the last language when asked to remove it`() {
        let selection = LanguageSelection(languages: [.japanese])

        #expect(selection.removing(.japanese) == selection)
    }

    @Test
    func `unpins a language that is removed`() {
        let selection = LanguageSelection(languages: [.english, .german], pinned: .english)

        #expect(selection.removing(.english).pinned == nil)
        #expect(selection.adding(.french).pinned == .english)
    }

    @Test(arguments: [
        (["de-DE", "en-US", "de-AT", "fr", "xx"], [Language.german, .french]),
        (["en-GB", "ru"], []),
        ([], []),
    ])
    func `suggests system languages that are not selected yet`(identifiers: [String], expected: [Language]) {
        let selection = LanguageSelection(languages: [.english, .russian])

        #expect(selection.suggestions(from: identifiers) == expected)
    }

    @Test
    func `pins and unpins`() {
        let selection = LanguageSelection(languages: [.english, .german])

        #expect(selection.pinning(.german).pinned == .german)
        #expect(selection.pinning(.korean).pinned == nil)
        #expect(selection.pinning(.german).pinning(nil).pinned == nil)
    }

    @Test(arguments: [
        (#"{"languages":["ru"],"pinned":"de"}"#, [Language.russian], Language?.none),
        (#"{"languages":["de","en"],"pinned":"en"}"#, [.english, .german], .english),
        (#"{"languages":["ru","xx","de"],"pinned":"de"}"#, [.german, .russian], .german),
        (#"{"languages":"bad","pinned":"xx"}"#, [.english], nil),
        (#"{}"#, [.english], nil),
    ])
    func `decodes leniently`(json: String, languages: [Language], pinned: Language?) throws {
        let selection = try JSONDecoder().decode(LanguageSelection.self, from: Data(json.utf8))

        #expect(selection.languages == languages)
        #expect(selection.pinned == pinned)
    }
}
