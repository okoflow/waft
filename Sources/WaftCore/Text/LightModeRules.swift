import Foundation

enum LightModeRules {
    static let framingMarks: Set<Character> = [",", "，", "、", "،", "…", "-", "–", "—"]

    static let openingMarks: Set<Character> = ["¿", "¡", "(", "[", "«", "„", "“", "\"", "「", "『", "（", "《"]

    static let groupClosingMarks: Set<Character> = ["?", "!", ")", "]", "»", "“", "”", "\"", "」", "』", "）", "》"]

    private static let sentenceEnds: Set<Character> = [".", "!", "?", "。", "！", "？", "؟", "۔", "।", "॥"]

    private static let closingMarks: Set<Character> = [
        ",",
        ".",
        "…",
        "，",
        "。",
        "、",
        "！",
        "？",
        "：",
        "；",
        "،",
        "؛",
        "؟",
        "۔",
        "।",
        "॥",
    ]

    private static let highMarks: Set<Character> = ["!", "?", ";", ":"]

    private static let hyphens: Set<Character> = ["-", "‐"]

    private static let inlineSpaces: Set<Character> = [" ", "\t"]

    static func apply(_ text: String, language: Language) -> String {
        var remover = HesitationRemover(language: language, text: text)

        let tidy = tidiedSpacing(remover.run(), language: language)

        return tidy.capitalizingFirstLetter(in: language).endingWithFullStop(in: language)
    }

    static func isHesitation(_ word: String, in language: Language) -> Bool {
        guard !isAbbreviation(word) else { return false }

        let letters = word.folded(in: language).filter { !hyphens.contains($0) }

        let runs = HesitationPattern.runs(of: letters)

        return HesitationPattern.patterns(for: language).contains { $0.matches(runs) }
    }

    static func endsSentence(_ mark: Character, in language: Language) -> Bool {
        guard !sentenceEnds.contains(mark) else { return true }

        return mark == language.questionMark
    }

    private static func isAbbreviation(_ word: String) -> Bool {
        guard word.count(where: \.isUppercase) > 1 else { return false }

        return !word.contains(where: \.isLowercase)
    }

    private static func tidiedSpacing(_ text: String, language: Language) -> String {
        let noSpaceBefore = language.spacesBeforeHighPunctuation ? closingMarks : closingMarks.union(highMarks)

        var result = ""
        var hasPendingSpace = false

        for character in text {
            if inlineSpaces.contains(character) {
                hasPendingSpace = true

                continue
            }

            if hasPendingSpace, let last = result.last, last != "\n", character != "\n", !noSpaceBefore.contains(character) {
                result.append(" ")
            }

            hasPendingSpace = false

            result.append(character)
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
