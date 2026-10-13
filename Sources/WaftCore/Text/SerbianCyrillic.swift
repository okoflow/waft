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
        let kept = Set(terms.flatMap { $0.lowercased().split(separator: " ").map(String.init) })
        var result = ""
        var word = ""

        for character in text {
            if character.isLetter || character.isNumber {
                word.append(character)
            } else {
                result += converted(word, keeping: kept)
                result.append(character)
                word = ""
            }
        }

        return result + converted(word, keeping: kept)
    }

    private static func converted(_ word: String, keeping kept: Set<String>) -> String {
        guard isSerbianLatin(word), !kept.contains(word.lowercased()) else { return word }

        let lowercased = word.lowercased()
        let keepsLettersApart = separateLetterPrefixes.contains { lowercased.hasPrefix($0) }
        var remaining = Substring(word)
        var result = ""

        while let first = remaining.first {
            let digraph = keepsLettersApart ? nil : digraphs.first { remaining.hasPrefix($0.latin) }

            if let digraph {
                result += digraph.cyrillic
                remaining = remaining.dropFirst(digraph.latin.count)
            } else {
                result.append(letters[first, default: first])
                remaining = remaining.dropFirst()
            }
        }

        return result
    }

    private static func isSerbianLatin(_ word: String) -> Bool {
        guard !word.isEmpty, word.allSatisfy({ letters[$0] != nil }) else { return false }

        let isAllCapitals = word.allSatisfy(\.isUppercase)
        let isAcronym = isAllCapitals && (2 ... 4).contains(word.count)
        let hasInnerCapital = !isAllCapitals && word.dropFirst().contains(where: \.isUppercase)

        return !isAcronym && !hasInnerCapital
    }
}
