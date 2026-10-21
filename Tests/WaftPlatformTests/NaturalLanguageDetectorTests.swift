import Testing
import WaftCore
import WaftPlatform

struct NaturalLanguageDetectorTests {
    @Test(arguments: [
        ("We meet at the office tomorrow afternoon to plan the next release.", Language.english),
        ("我们明天下午三点在公司开会，请准时参加。", .chinese),
        ("我們明天下午三點在公司開會，請準時參加。", .chinese),
        ("Jeg skal gå på butikken i morgen for å kjøpe melk og brød til frokost.", .norwegian),
    ])
    func `recognizes the language of a text`(text: String, language: Language) {
        #expect(NaturalLanguageDetector().language(of: text) == language)
    }

    @Test
    func `recognizes no language in a text without words`() {
        #expect(NaturalLanguageDetector().language(of: "1234 5678") == nil)
    }
}
