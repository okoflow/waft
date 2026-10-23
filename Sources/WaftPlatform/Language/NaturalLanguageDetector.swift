package import WaftCore
import NaturalLanguage

package struct NaturalLanguageDetector: LanguageDetector {
    private static let minimumConfidence = 0.5
    private static let minimumExpectedConfidence = 0.25
    private static let expectedShare = 0.85
    private static let hypothesisCount = 4

    private static let constraints = Language.allCases.flatMap(naturalLanguages)

    package init() {}

    private static func naturalLanguages(for language: Language) -> [NLLanguage] {
        switch language {
        case .chinese: [.simplifiedChinese, .traditionalChinese]
        case .norwegian: [.norwegian]
        default: [NLLanguage(language.localeCode)]
        }
    }

    private static func hints(expecting expected: [Language]) -> [NLLanguage: Double] {
        let expectedLanguages = Set(expected.flatMap(naturalLanguages))
        guard !expectedLanguages.isEmpty else { return [:] }

        let others = constraints.filter { !expectedLanguages.contains($0) }

        let expectedHints = expectedLanguages.map { ($0, expectedShare / Double(expectedLanguages.count)) }
        let otherHints = others.map { ($0, (1 - expectedShare) / Double(others.count)) }

        return Dictionary(expectedHints + otherHints) { first, _ in first }
    }

    private static func rankedGuesses(in hypotheses: [NLLanguage: Double]) -> [(language: Language, confidence: Double)] {
        var confidences: [Language: Double] = [:]

        for (naturalLanguage, confidence) in hypotheses {
            guard let language = Language(localeIdentifier: naturalLanguage.rawValue) else { continue }

            confidences[language, default: 0] += confidence
        }

        return confidences.map { (language: $0.key, confidence: $0.value) }.sorted { $0.confidence > $1.confidence }
    }

    package func language(of text: String, expecting expected: [Language]) -> Language? {
        let recognizer = NLLanguageRecognizer()
        recognizer.languageConstraints = Self.constraints
        recognizer.languageHints = Self.hints(expecting: expected)
        recognizer.processString(text)

        let guesses = Self.rankedGuesses(in: recognizer.languageHypotheses(withMaximum: Self.hypothesisCount))

        if let likely = guesses.first(where: { expected.contains($0.language) }),
           likely.confidence >= Self.minimumExpectedConfidence {
            return likely.language
        }

        guard let best = guesses.first, best.confidence >= Self.minimumConfidence else { return nil }

        return best.language
    }
}
