import WaftCore
@preconcurrency import WhisperKit

struct LanguageRestrictedTokenizer: WhisperTokenizer {
    let allLanguageTokens: Set<Int>

    private let base: any WhisperTokenizer

    var specialTokens: SpecialTokens {
        base.specialTokens
    }

    init(restricting base: (any WhisperTokenizer)?, to languages: [Language]) throws(TranscriberError) {
        guard let base else { throw .tokenizerMissing }

        let tokens = Set(languages.compactMap { base.convertTokenToId("<|\($0.rawValue)|>") })
        guard !tokens.isEmpty, tokens.count == languages.count else { throw .languageTokensMissing }

        self.base = base
        allLanguageTokens = tokens
    }

    func encode(text: String) -> [Int] {
        base.encode(text: text)
    }

    func decode(tokens: [Int]) -> String {
        base.decode(tokens: tokens)
    }

    func convertTokenToId(_ token: String) -> Int? {
        base.convertTokenToId(token)
    }

    func convertIdToToken(_ id: Int) -> String? {
        base.convertIdToToken(id)
    }

    func splitToWordTokens(tokenIds: [Int]) -> (words: [String], wordTokens: [[Int]]) {
        base.splitToWordTokens(tokenIds: tokenIds)
    }
}
