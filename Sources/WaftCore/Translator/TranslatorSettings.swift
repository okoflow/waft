package struct TranslatorSettings: Codable, Equatable, Sendable {
    private static let maximumRecentCount = 3

    package var source: Language?
    package var translation: Translation
    package var rephrases = false
    package private(set) var recentLanguages: [Language] = []

    package init(translation: Translation = Translation()) {
        self.translation = translation
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        source = container.decodeIfValid(.source)
        translation = container.decode(.translation, default: Translation())
        rephrases = container.decode(.rephrases, default: rephrases)
        recentLanguages = Array(container.decodeValidElements(.recentLanguages).prefix(Self.maximumRecentCount))
    }

    package func target(forSource source: Language?) -> Language {
        guard let source else { return translation.target }

        return translation.target(forSpoken: source)
    }

    package mutating func remember(_ language: Language) {
        recentLanguages.removeAll { $0 == language }
        recentLanguages.insert(language, at: 0)
        recentLanguages = Array(recentLanguages.prefix(Self.maximumRecentCount))
    }
}
