struct TextSegment: Equatable {
    private static let innerJoiners: Set<Character> = ["-", "'", "’", "‐", "\"", "׳", "״"]

    var text: String
    let isWord: Bool

    static func split(_ text: String) -> [TextSegment] {
        let characters = Array(text)

        var segments: [TextSegment] = []

        for index in characters.indices {
            let isWordCharacter = isWordCharacter(at: index, in: characters)

            if let last = segments.last, last.isWord == isWordCharacter {
                segments[segments.count - 1].text.append(characters[index])
            } else {
                segments.append(TextSegment(text: String(characters[index]), isWord: isWordCharacter))
            }
        }

        return segments
    }

    static func words(of text: String, in language: Language) -> [String] {
        split(text).filter(\.isWord).map { $0.text.normalizedWord(in: language) }
    }

    private static func isWordCharacter(at index: Int, in characters: [Character]) -> Bool {
        let character = characters[index]
        guard !character.isLetterOrNumber else { return true }

        let isMark = character.unicodeScalars.allSatisfy { $0.properties.generalCategory == .nonspacingMark }
        guard !isMark else { return true }

        return isInnerJoiner(at: index, in: characters)
    }

    private static func isInnerJoiner(at index: Int, in characters: [Character]) -> Bool {
        guard innerJoiners.contains(characters[index]), index > 0, index + 1 < characters.count,
              characters[index - 1].isLetterOrNumber else { return false }

        return characters[index + 1].isLetter
    }
}
