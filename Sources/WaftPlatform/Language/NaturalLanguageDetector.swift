package import WaftCore
import NaturalLanguage

package struct NaturalLanguageDetector: LanguageDetector {
    private static let minimumConfidence = 0.5

    private static let constraints = Language.allCases.map { NLLanguage($0.localeCode) }

    package init() {}

    package func language(of text: String) -> Language? {
        let recognizer = NLLanguageRecognizer()
        recognizer.languageConstraints = Self.constraints
        recognizer.processString(text)

        guard let language = recognizer.dominantLanguage,
              recognizer.languageHypotheses(withMaximum: 1)[language, default: 0] >= Self.minimumConfidence
        else { return nil }

        return Language(localeIdentifier: language.rawValue)
    }
}
