package struct LanguageSelection: Codable, Equatable, Sendable {
    private static let maximumPreferredCount = 3

    package private(set) var languages: [Language]
    package private(set) var pinned: Language?

    package var forcedLanguage: Language? {
        if let pinned {
            return pinned
        }

        return languages.count == 1 ? languages.first : nil
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init(languages: container.decodeValidElements(.languages), pinned: container.decodeIfValid(.pinned))
    }

    init(languages: [Language], pinned: Language? = nil) {
        let ordered = Language.allCases.filter(languages.contains)
        let enabled = ordered.isEmpty ? [Language.english] : ordered

        self.languages = enabled
        self.pinned = pinned.flatMap { enabled.contains($0) ? $0 : nil }
    }

    package static func preferred(by localeIdentifiers: [String]) -> LanguageSelection {
        let preferred = Array(distinctLanguages(in: localeIdentifiers, excluding: []).prefix(maximumPreferredCount))

        return LanguageSelection(languages: preferred.contains(.english) ? preferred : preferred + [.english])
    }

    private static func distinctLanguages(in localeIdentifiers: [String], excluding excluded: [Language]) -> [Language] {
        var seen = Set(excluded)

        return localeIdentifiers.compactMap(Language.init(localeIdentifier:)).filter { seen.insert($0).inserted }
    }

    package func suggestions(from localeIdentifiers: [String]) -> [Language] {
        Self.distinctLanguages(in: localeIdentifiers, excluding: languages)
    }

    package func adding(_ language: Language) -> LanguageSelection {
        LanguageSelection(languages: languages + [language], pinned: pinned)
    }

    package func removing(_ language: Language) -> LanguageSelection {
        let remaining = languages.filter { $0 != language }
        guard !remaining.isEmpty else { return self }

        return LanguageSelection(languages: remaining, pinned: pinned)
    }

    package func pinning(_ language: Language?) -> LanguageSelection {
        LanguageSelection(languages: languages, pinned: language)
    }
}
