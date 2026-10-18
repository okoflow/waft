import Foundation

enum LightModeRules {
    static let framingMarks: Set<Character> = [",", "，", "、", "،", "…", "-", "–", "—"]

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

    static func apply(_ text: String, language: Language) -> String {
        var remover = HesitationRemover(language: language, text: text)

        let tidy = tidiedSpacing(remover.run(), language: language)
        let cased = language.hasLetterCase ? tidy.capitalizingFirstLetter(in: language) : tidy

        return cased.endingWithFullStop(in: language)
    }

    static func isHesitation(_ word: String, in language: Language) -> Bool {
        let isAbbreviation = word.count(where: \.isUppercase) > 1 && !word.contains(where: \.isLowercase)
        guard !isAbbreviation else { return false }

        let letters = word.folded(in: language).filter { $0 != "-" && $0 != "‐" }
        let runs = HesitationPattern.runs(of: letters)

        return HesitationPattern.patterns(for: language).contains { $0.matches(runs) }
    }

    static func endsSentence(_ mark: Character, in language: Language) -> Bool {
        sentenceEnds.contains(mark) || mark == language.questionMark
    }

    private static func tidiedSpacing(_ text: String, language: Language) -> String {
        let noSpaceBefore = language.spacesBeforeHighPunctuation ? closingMarks : closingMarks.union(highMarks)
        var result = ""
        var hasPendingSpace = false

        for character in text {
            if character == " " || character == "\t" {
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
