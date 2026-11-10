import Foundation

enum LightModeRules {
    private static let highMarks: Set<Character> = ["!", "?", ";", ":"]

    private static let inlineSpaces: Set<Character> = [" ", "\t"]

    static func apply(_ text: String, language: Language) -> String {
        var remover = HesitationRemover(language: language, text: text)

        let tidy = tidiedSpacing(remover.run(), language: language)

        return tidy.capitalizingFirstLetter(in: language).endingWithFullStop(in: language)
    }

    private static func tidiedSpacing(_ text: String, language: Language) -> String {
        var result = ""
        var hasPendingSpace = false

        for character in text {
            if inlineSpaces.contains(character) {
                hasPendingSpace = true

                continue
            }

            if hasPendingSpace, let last = result.last, takesSpace(between: last, and: character, in: language) {
                result.append(" ")
            }

            hasPendingSpace = false

            result.append(character)
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func takesSpace(between last: Character, and next: Character, in language: Language) -> Bool {
        guard last != "\n", next != "\n" else { return false }
        guard next.isPauseMark else { return true }
        guard language.spacesBeforeHighPunctuation else { return false }

        return highMarks.contains(next)
    }
}
