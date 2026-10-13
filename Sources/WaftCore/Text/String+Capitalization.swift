import Foundation

extension String {
    package func capitalizedIfUnstyled(in language: Language) -> String {
        guard language.hasLetterCase, !contains(where: \.isUppercase), !contains(where: \.isPunctuation) else { return self }

        return capitalizingFirstLetter(in: language)
    }

    func capitalizingFirstLetter(in language: Language) -> String {
        guard let index = firstIndex(where: \.isLetter), self[index].isLowercase else { return self }

        let capital = language.hasDottedCapitalI && self[index] == "i" ? "İ" : self[index].uppercased()

        return replacingCharacters(in: index ... index, with: capital)
    }
}
