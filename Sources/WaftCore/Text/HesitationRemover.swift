import Foundation

struct HesitationRemover {
    private let language: Language
    private let segments: [TextSegment]
    private var kept: [TextSegment] = []
    private var previousWord: String?
    private var capitalizesNextWord = false
    private var index = 0

    private var followsNumber: Bool {
        guard let previousWord, let gap = kept.last, previousWord.allSatisfy(\.isNumber) else { return false }

        return gap.text.allSatisfy(\.isWhitespace)
    }

    init(language: Language, text: String) {
        self.language = language
        segments = TextSegment.split(text.replacingOccurrences(of: "...", with: "…"))
    }

    private static func keptMark(_ before: String, _ after: String) -> String {
        let isFraming = LightModeRules.framingMarks.contains
        let trimmedBefore = before.trimmingCharacters(in: .whitespacesAndNewlines)

        let left = String(trimmedBefore.reversed().drop(while: isFraming).reversed())
        guard left.isEmpty else { return left }

        let trimmedAfter = after.trimmingCharacters(in: .whitespacesAndNewlines)

        return String(trimmedAfter.drop(while: isFraming))
    }

    private static func splittingOpeningMarks(off separator: String) -> (closing: String, opening: String) {
        let opening = String(separator.reversed().prefix(while: LightModeRules.openingMarks.contains).reversed())

        return (String(separator.dropLast(opening.count)), opening)
    }

    private static func movesOpening(_ opening: String, across closing: String) -> Bool {
        guard !opening.isEmpty else { return false }

        return closing.trimmingCharacters(in: .whitespacesAndNewlines).allSatisfy(LightModeRules.framingMarks.contains)
    }

    private static func keepsMark(_ mark: String, before opening: String, movesOpening: Bool) -> Bool {
        guard !movesOpening else { return true }

        return [mark, opening].allSatisfy { !$0.isEmpty }
    }

    mutating func run() -> String {
        while index < segments.count {
            let segment = segments[index]

            index += 1

            guard segment.isWord else {
                kept.append(segment)

                continue
            }
            guard !followsNumber, LightModeRules.isHesitation(segment.text, in: language) else {
                keep(segment)

                continue
            }

            removeHesitation()
        }

        return kept.map(\.text).joined()
    }

    private mutating func keep(_ word: TextSegment) {
        kept.append(capitalizedIfStartingSentence(word))

        capitalizesNextWord = false
        previousWord = word.text
    }

    private func capitalizedIfStartingSentence(_ word: TextSegment) -> TextSegment {
        guard capitalizesNextWord else { return word }

        return TextSegment(text: word.text.capitalizingFirstLetter(in: language), isWord: true)
    }

    private mutating func removeHesitation() {
        let before = takeKeptSeparator()
        let after = takeSeparator()

        let isAtStart = !kept.contains(where: \.isWord)
        let isAtEnd = !segments[index...].contains(where: \.isWord)

        let separator = joinedSeparator(before, after, isAtStart: isAtStart, isAtEnd: isAtEnd)

        if !separator.isEmpty {
            kept.append(TextSegment(text: separator, isWord: false))
        }

        if startsSentence(after: separator, isAtStart: isAtStart) {
            capitalizesNextWord = true
        }
    }

    private mutating func takeKeptSeparator() -> String {
        guard let last = kept.last, !last.isWord else { return "" }

        return kept.removeLast().text
    }

    private mutating func takeSeparator() -> String {
        guard index < segments.count, !segments[index].isWord else { return "" }

        let separator = segments[index].text

        index += 1

        return separator
    }

    private func startsSentence(after separator: String, isAtStart: Bool) -> Bool {
        guard !isAtStart else { return true }

        return separator.contains { LightModeRules.endsSentence($0, in: language) }
    }

    private func joinedSeparator(_ before: String, _ after: String, isAtStart: Bool, isAtEnd: Bool) -> String {
        let (closingBefore, openingBefore) = Self.splittingOpeningMarks(off: before)
        let marksAfter = after.drop(while: \.isWhitespace)

        let closesGroup = marksAfter.first.map(LightModeRules.groupClosingMarks.contains) == true

        if !openingBefore.isEmpty, closesGroup {
            return joinedSeparator(closingBefore, String(marksAfter.dropFirst()), isAtStart: isAtStart, isAtEnd: isAtEnd)
        }

        if isAtStart, isAtEnd {
            return ""
        }

        guard !isAtEnd else { return Self.keptMark(before, after) }

        let (closingAfter, openingAfter) = Self.splittingOpeningMarks(off: after)

        let movesOpening = Self.movesOpening(openingBefore, across: closingAfter)

        let opening = movesOpening ? openingBefore + openingAfter : openingAfter

        guard !isAtStart else { return opening }

        let markBefore = closingBefore.trimmingCharacters(in: .whitespacesAndNewlines)

        let keepsMarkBefore = Self.keepsMark(markBefore, before: openingAfter, movesOpening: movesOpening)

        let mark = keepsMarkBefore ? markBefore : Self.keptMark(before, closingAfter)
        let gap = (before + after).contains("\n") ? "\n" : language.wordSeparator

        return mark + gap + opening
    }
}
