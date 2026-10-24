import Foundation

enum SerbianCyrillic {
    private static let digraphs: [(latin: String, cyrillic: String)] = [
        ("dž", "џ"),
        ("Dž", "Џ"),
        ("DŽ", "Џ"),
        ("lj", "љ"),
        ("Lj", "Љ"),
        ("LJ", "Љ"),
        ("nj", "њ"),
        ("Nj", "Њ"),
        ("NJ", "Њ"),
    ]

    private static let letters: [Character: Character] = [
        "a": "а",
        "b": "б",
        "c": "ц",
        "č": "ч",
        "ć": "ћ",
        "d": "д",
        "đ": "ђ",
        "e": "е",
        "f": "ф",
        "g": "г",
        "h": "х",
        "i": "и",
        "j": "ј",
        "k": "к",
        "l": "л",
        "m": "м",
        "n": "н",
        "o": "о",
        "p": "п",
        "r": "р",
        "s": "с",
        "š": "ш",
        "t": "т",
        "u": "у",
        "v": "в",
        "z": "з",
        "ž": "ж",
        "A": "А",
        "B": "Б",
        "C": "Ц",
        "Č": "Ч",
        "Ć": "Ћ",
        "D": "Д",
        "Đ": "Ђ",
        "E": "Е",
        "F": "Ф",
        "G": "Г",
        "H": "Х",
        "I": "И",
        "J": "Ј",
        "K": "К",
        "L": "Л",
        "M": "М",
        "N": "Н",
        "O": "О",
        "P": "П",
        "R": "Р",
        "S": "С",
        "Š": "Ш",
        "T": "Т",
        "U": "У",
        "V": "В",
        "Z": "З",
        "Ž": "Ж",
    ]

    private static let separateLetterPrefixes = ["nadž", "podž", "injek", "konjug", "konjunk", "vanjez"]

    static func converting(_ text: String, keeping terms: [String]) -> String {
        var result = ""
        var start = text.startIndex

        for range in keptRanges(of: terms, in: text) {
            result += convertingWords(in: text[start ..< range.lowerBound])
            result += text[range]
            start = range.upperBound
        }

        return result + convertingWords(in: text[start...])
    }

    private static func keptRanges(of terms: [String], in text: String) -> [Range<String.Index>] {
        let ranges = terms.flatMap { wholeWordRanges(of: $0, in: text) }.sorted { $0.lowerBound < $1.lowerBound }

        var kept: [Range<String.Index>] = []

        for range in ranges where !kept.contains(where: { $0.overlaps(range) }) {
            kept.append(range)
        }

        return kept
    }

    private static func wholeWordRanges(of term: String, in text: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchStart = text.startIndex

        while let range = text.range(of: term, options: .caseInsensitive, range: searchStart ..< text.endIndex) {
            if !isWordCharacter(text[..<range.lowerBound].last), !isWordCharacter(text[range.upperBound...].first) {
                ranges.append(range)
            }

            searchStart = range.upperBound
        }

        return ranges
    }

    private static func isWordCharacter(_ character: Character?) -> Bool {
        guard let character else { return false }

        return character.isLetterOrNumber
    }

    private static func convertingWords(in text: Substring) -> String {
        var result = ""
        var word = ""

        for character in text {
            guard !isWordCharacter(character) else {
                word.append(character)

                continue
            }

            result += converted(word)
            result.append(character)
            word = ""
        }

        return result + converted(word)
    }

    private static func converted(_ word: String) -> String {
        guard isSerbianLatin(word) else { return word }

        let lowercased = word.lowercased()

        let keepsLettersApart = separateLetterPrefixes.contains { lowercased.hasPrefix($0) }

        var remaining = Substring(word)
        var result = ""

        while let first = remaining.first {
            if !keepsLettersApart, let digraph = digraphs.first(where: { remaining.hasPrefix($0.latin) }) {
                result += digraph.cyrillic
                remaining = remaining.dropFirst(digraph.latin.count)

                continue
            }

            result.append(letters[first, default: first])
            remaining = remaining.dropFirst()
        }

        return result
    }

    private static func isSerbianLatin(_ word: String) -> Bool {
        guard !word.isEmpty, word.allSatisfy({ letters[$0] != nil }) else { return false }
        guard word.allSatisfy(\.isUppercase) else { return !word.dropFirst().contains(where: \.isUppercase) }

        return !(2 ... 4).contains(word.count)
    }
}
