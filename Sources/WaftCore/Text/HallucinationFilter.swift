package enum HallucinationFilter {
    private static let minimumAverageLogProbability = -1.5
    private static let maximumCompressionRatio = 2.4

    private static let enclosingPairs: [(open: Character, close: Character)] = [
        ("[", "]"),
        ("(", ")"),
        ("（", "）"),
        ("【", "】"),
        ("*", "*"),
    ]

    package static func keepsSegment(averageLogProbability: Double, compressionRatio: Double) -> Bool {
        guard averageLogProbability >= minimumAverageLogProbability else { return false }

        return compressionRatio <= maximumCompressionRatio
    }

    package static func isHallucination(
        _ text: String,
        in language: Language,
        prompt: String?,
        vocabulary: [String] = [],
    ) -> Bool {
        guard !isOnlySoundTags(text),
              !isEcho(of: prompt, in: text, language: language, vocabulary: vocabulary) else { return true }

        return isStockPhrase(text, in: language)
    }

    private static func isOnlySoundTags(_ text: String) -> Bool {
        var depth: [Character] = []

        for character in text where character != "♪" {
            if let pair = enclosingPairs.first(where: { $0.close == character }), depth.last == pair.open {
                depth.removeLast()

                continue
            }

            if let pair = enclosingPairs.first(where: { $0.open == character }) {
                depth.append(pair.open)

                continue
            }

            if depth.isEmpty, character.isLetterOrNumber {
                return false
            }
        }

        return true
    }

    private static func isEcho(of prompt: String?, in text: String, language: Language, vocabulary: [String]) -> Bool {
        guard let prompt else { return false }

        let normalized = text.normalizedForComparison(in: language)
        guard !normalized.isEmpty else { return false }

        let normalizedPrompt = prompt.normalizedForComparison(in: language)
        guard normalized.count * 2 >= normalizedPrompt.count, normalizedPrompt.contains(normalized) else { return false }

        return !vocabulary.contains { $0.normalizedForComparison(in: language) == normalized }
    }

    private static func isStockPhrase(_ text: String, in language: Language) -> Bool {
        let normalized = text.normalizedForComparison(in: language)

        return StockPhrase.phrases(for: language).contains { phrase in
            let known = phrase.text.normalizedForComparison(in: language)
            guard normalized.hasPrefix(known) else { return false }

            let rest = normalized.dropFirst(known.count)

            guard language.hasLooseWordSpacing else { return rest.split(separator: " ").count <= phrase.trailingWords }

            return rest.count <= phrase.trailingWords * 3
        }
    }
}
