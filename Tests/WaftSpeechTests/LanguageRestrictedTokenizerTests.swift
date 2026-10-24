import Testing
import WaftCore
@testable import WaftSpeech
@preconcurrency import WhisperKit

struct LanguageRestrictedTokenizerTests {
    private static let base = FakeWhisperTokenizer(
        tokensByText: [" hello": [31373]],
        idsByToken: ["<|en|>": 50259, "<|de|>": 50261, "<|ru|>": 50263],
    )

    @Test
    func `refuses a model without a tokenizer`() {
        #expect(throws: TranscriberError.tokenizerMissing) {
            try LanguageRestrictedTokenizer(restricting: nil, to: [.english])
        }
    }

    @Test(arguments: [[Language.english, .japanese], []])
    func `refuses languages the tokenizer has no token for`(languages: [Language]) {
        #expect(throws: TranscriberError.languageTokensMissing) {
            try LanguageRestrictedTokenizer(restricting: Self.base, to: languages)
        }
    }

    @Test
    func `detects only the chosen languages and forwards everything else`() throws {
        let tokenizer = try LanguageRestrictedTokenizer(restricting: Self.base, to: [.english, .german])

        #expect(tokenizer.allLanguageTokens == [50259, 50261])
        #expect(tokenizer.encode(text: " hello") == [31373])
        #expect(tokenizer.convertTokenToId("<|ru|>") == 50263)
        #expect(tokenizer.specialTokens.specialTokenBegin == FakeWhisperTokenizer.specialTokenBegin)
    }
}
