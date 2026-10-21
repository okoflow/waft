package import WaftCore
import NaturalLanguage

package struct NaturalLanguageDetector: LanguageDetector {
    private static let minimumConfidence = 0.5

    private static let constraints = Language.allCases.flatMap(naturalLanguages)

    package init() {}

    private static func naturalLanguages(for language: Language) -> [NLLanguage] {
        switch language {
        case .chinese: [.simplifiedChinese, .traditionalChinese]
        case .norwegian: [.norwegian]
        default: [NLLanguage(language.localeCode)]
        }
    }

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
