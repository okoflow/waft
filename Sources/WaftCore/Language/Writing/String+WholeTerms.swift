import Foundation

extension String {
    private static func continuesWord(_ character: Character?) -> Bool {
        guard let character, character.isLetterOrNumber else { return false }

        return !character.unicodeScalars.contains { WritingScript($0)?.separatesWordsWithSpaces == false }
    }

    func rangesOfWholeTerms(_ terms: [String]) -> [Range<String.Index>] {
        let ranges = terms.flatMap(rangesOfWholeTerm).sorted { $0.lowerBound < $1.lowerBound }

        var kept: [Range<String.Index>] = []

        for range in ranges where !kept.contains(where: { $0.overlaps(range) }) {
            kept.append(range)
        }

        return kept
    }

    private func rangesOfWholeTerm(_ term: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchStart = startIndex

        while let range = range(of: term, options: .caseInsensitive, range: searchStart ..< endIndex) {
            if !Self.continuesWord(self[..<range.lowerBound].last), !Self.continuesWord(self[range.upperBound...].first) {
                ranges.append(range)
            }

            searchStart = range.upperBound
        }

        return ranges
    }
}
