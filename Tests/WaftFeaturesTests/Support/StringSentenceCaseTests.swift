import Foundation
import Testing
@testable import WaftFeatures

struct StringSentenceCaseTests {
    @Test(arguments: [("you're offline", "en", "You're offline"), ("istanbul", "tr", "İstanbul"), ("", "en", "")])
    func `capitalizes only the first letter the way the locale does`(text: String, locale: String, expected: String) {
        #expect(text.sentenceCased(in: Locale(identifier: locale)) == expected)
    }
}
