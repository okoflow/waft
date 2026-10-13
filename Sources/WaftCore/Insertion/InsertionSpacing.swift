import Foundation

package enum InsertionSpacing {
    private static let openingCharacters: Set<Character> = ["(", "[", "{", "<", "\"", "'", "‘", "“", "«", "„", "/"]

    package static func prepared(_ text: String, after characterBeforeCaret: Character?) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first, let previous = characterBeforeCaret else { return trimmed }

        let continuesWithoutSpace = previous.isWhitespace || openingCharacters.contains(previous)
        let isUnspacedScript = isWrittenWithoutSpaces(previous) || isWrittenWithoutSpaces(first)

        return continuesWithoutSpace || isUnspacedScript ? trimmed : " " + trimmed
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

            return script == .han || script == .kana
        }
    }
}
