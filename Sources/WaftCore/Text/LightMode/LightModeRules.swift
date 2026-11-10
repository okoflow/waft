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
        let followers = text.dropFirst().map(Optional.some) + [nil]

        var result = ""
        var hasPendingSpace = false

        for (character, follower) in zip(text, followers) {
            if inlineSpaces.contains(character) {
                hasPendingSpace = true

                continue
            }

            if hasPendingSpace,
               let last = result.last,
               takesSpace(between: last, and: character, before: follower, in: language) {
                result.append(" ")
            }

            hasPendingSpace = false

            result.append(character)
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func takesSpace(
        between last: Character,
        and next: Character,
        before follower: Character?,
        in language: Language,
    ) -> Bool {
        guard last != "\n", next != "\n" else { return false }
        guard next.isPauseMark, !startsWord(next, before: follower) else { return true }
        guard language.spacesBeforeHighPunctuation else { return false }

        return highMarks.contains(next)
    }

    private static func startsWord(_ mark: Character, before follower: Character?) -> Bool {
        guard mark.isASCII, let follower else { return false }

        return follower.isLetterOrNumber
    }
}
