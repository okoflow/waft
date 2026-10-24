import Foundation
import Testing
@testable import WaftCore

struct WritingVariantsTests {
    @Test(arguments: [(Language.chinese, WritingVariant?.some(.simplified)), (.serbian, .latin), (.german, nil)])
    func `starts with the first script of each language`(language: Language, expected: WritingVariant?) {
        #expect(WritingVariants().variant(for: language) == expected)
    }

    @Test
    func `remembers the chosen script and ignores one the language does not have`() {
        let variants = WritingVariants()
            .choosing(.traditional, for: .chinese)
            .choosing(.cyrillic, for: .chinese)

        #expect(variants.variant(for: .chinese) == .traditional)
    }

    @Test
    func `survives an encoding round trip and drops unknown entries`() throws {
        let variants = WritingVariants().choosing(.cyrillic, for: .serbian)

        let data = try JSONEncoder().encode(variants)
        let stored = Data(#"{"sr":"cyrillic","zh":"klingon","xx":"latin"}"#.utf8)

        #expect(try JSONDecoder().decode(WritingVariants.self, from: data) == variants)
        #expect(try JSONDecoder().decode(WritingVariants.self, from: stored) == variants)
    }
}
