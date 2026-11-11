@preconcurrency import WhisperKit

struct FakeWhisperTokenizer: WhisperTokenizer {
    static let specialTokenBegin = 50257

    let allLanguageTokens: Set<Int> = []

    private let tokensByText: [String: [Int]]
    private let idsByToken: [String: Int]

    var specialTokens: SpecialTokens {
        SpecialTokens(
            endToken: 50257,
            englishToken: 50259,
            noSpeechToken: 50363,
            noTimestampsToken: 50364,
            specialTokenBegin: Self.specialTokenBegin,
            startOfPreviousToken: 50362,
            startOfTranscriptToken: 50258,
            timeTokenBegin: 50365,
            transcribeToken: 50360,
            translateToken: 50359,
            whitespaceToken: 220,
        )
    }

    init(tokensByText: [String: [Int]] = [:], idsByToken: [String: Int] = [:]) {
        self.tokensByText = tokensByText
        self.idsByToken = idsByToken
    }

    func encode(text: String) -> [Int] {
        tokensByText[text, default: []]
    }

    func decode(tokens: [Int]) -> String {
        tokens.map(String.init).joined(separator: " ")
    }

    func convertTokenToId(_ token: String) -> Int? {
        idsByToken[token]
    }

    func convertIdToToken(_ id: Int) -> String? {
        idsByToken.first { $0.value == id }?.key
    }

    func splitToWordTokens(tokenIds: [Int]) -> (words: [String], wordTokens: [[Int]]) {
        (tokenIds.map(String.init), tokenIds.map { [$0] })
    }
}
