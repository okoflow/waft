package struct WritingVariants: Equatable, Sendable {
    private var chosen: [Language: WritingVariant]

    init(_ chosen: [Language: WritingVariant] = [:]) {
        self.chosen = chosen.filter { $0.key.writingVariants.contains($0.value) }
    }

    package func variant(for language: Language) -> WritingVariant? {
        guard let standard = language.writingVariants.first else { return nil }

        return chosen[language, default: standard]
    }

    package func choosing(_ variant: WritingVariant, for language: Language) -> WritingVariants {
        guard language.writingVariants.contains(variant) else { return self }

        var chosen = chosen

        chosen[language] = variant

        return WritingVariants(chosen)
    }
}

extension WritingVariants: Codable {
    package init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        let stored = try container.decode([String: String].self)

        let pairs = stored.compactMap { key, value -> (Language, WritingVariant)? in
            guard let language = Language(rawValue: key), let variant = WritingVariant(rawValue: value) else { return nil }

            return (language, variant)
        }

        self.init(Dictionary(pairs) { first, _ in first })
    }

    package func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        let stored = Dictionary(uniqueKeysWithValues: chosen.map { ($0.key.rawValue, $0.value.rawValue) })

        try container.encode(stored)
    }
}
