import Foundation
import Testing
@testable import WaftCore

struct TranslationTests {
    @Test(arguments: [(Language.english, Language.russian), (.german, .english), (.russian, .english)])
    func `translates into the target unless the target language was spoken`(spoken: Language, expected: Language) {
        let translation = Translation(target: .english, twoWayLanguage: .russian)

        #expect(translation.target(forSpoken: spoken) == expected)
    }

    @Test(arguments: [Language.german, .english, .japanese])
    func `translates one way without a second language`(spoken: Language) {
        #expect(Translation(target: .german).target(forSpoken: spoken) == .german)
    }

    @Test
    func `drops a second language equal to the target`() {
        let translation = Translation(target: .french, twoWayLanguage: .french)

        #expect(translation.twoWayLanguage == nil)
        #expect(translation.target(forSpoken: .french) == .french)
    }

    @Test
    func `drops the second language when either side changes to match the other`() {
        var translation = Translation(target: .english, twoWayLanguage: .russian)
        translation.target = .russian

        #expect(translation.twoWayLanguage == nil)

        translation.twoWayLanguage = .russian

        #expect(translation.twoWayLanguage == nil)

        translation.twoWayLanguage = .german

        #expect(translation.twoWayLanguage == .german)
    }

    @Test(arguments: [
        (#"{}"#, Translation()),
        (#"{"target":"de","twoWayLanguage":"uk"}"#, Translation(target: .german, twoWayLanguage: .ukrainian)),
        (#"{"target":"de","twoWayLanguage":"de"}"#, Translation(target: .german)),
        (#"{"target":"xx","twoWayLanguage":"ru"}"#, Translation(target: .english, twoWayLanguage: .russian)),
        (#"{"target":"ja","twoWayLanguage":42}"#, Translation(target: .japanese)),
    ])
    func `decodes leniently`(json: String, expected: Translation) throws {
        #expect(try JSONDecoder().decode(Translation.self, from: Data(json.utf8)) == expected)
    }
}
