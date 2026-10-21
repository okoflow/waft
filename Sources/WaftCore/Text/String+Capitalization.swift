import Foundation

extension String {
    private static func capital(of letter: Character, in language: Language) -> String {
        guard language.hasDottedCapitalI, letter == "i" else { return letter.uppercased() }

        return "İ"
    }

    package func capitalizedIfUnstyled(in language: Language) -> String {
        guard !contains(where: \.isUppercase), !contains(where: \.isPunctuation) else { return self }

        return capitalizingFirstLetter(in: language)
    }

    func capitalizingFirstLetter(in language: Language) -> String {
        guard language.hasLetterCase, let index = firstIndex(where: \.isLetter), self[index].isLowercase else { return self }

        let firstWord = self[index...].prefix(while: \.isLetter)
        guard !firstWord.contains(where: \.isUppercase) else { return self }

        return replacingCharacters(in: index ... index, with: Self.capital(of: self[index], in: language))
    }
}
