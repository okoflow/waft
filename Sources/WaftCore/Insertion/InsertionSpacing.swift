import Foundation

package enum InsertionSpacing {
    private static let openingCharacters: Set<Character> = ["(", "[", "{", "<", "\"", "'", "‘", "“", "«", "„", "/"]

    package static func prepared(_ text: String, after characterBeforeCaret: Character?) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard let first = trimmed.first, let previous = characterBeforeCaret, !previous.isWhitespace, !first.isNewline,
              !openingCharacters.contains(previous), !isWrittenWithoutSpaces(previous),
              !isWrittenWithoutSpaces(first) else { return trimmed }

        return " " + trimmed
    }

    private static func isWrittenWithoutSpaces(_ character: Character) -> Bool {
        character.unicodeScalars.contains(where: isUnspaced)
    }

    private static func isUnspaced(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x3000 ... 0x303F, 0xFF00 ... 0xFFEF:
            return true
        default:
            guard let script = WritingScript(scalar) else { return false }

            return [WritingScript.han, .kana].contains(script)
        }
    }
}
