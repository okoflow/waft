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

    mutating func run() -> String {
        while index < segments.count {
            let segment = segments[index]
            index += 1

            if !segment.isWord {
                kept.append(segment)
            } else if isRemovable(segment) {
                removeHesitation()
            } else {
                keep(segment)
            }
        }

        return kept.map(\.text).joined()
    }

    private func isRemovable(_ word: TextSegment) -> Bool {
        guard !followsNumber else { return false }

        return LightModeRules.isHesitation(word.text, in: language)
    }

    private mutating func keep(_ word: TextSegment) {
        let capitalizes = capitalizesNextWord && language.hasLetterCase

        kept.append(capitalizes ? TextSegment(text: word.text.capitalizingFirstLetter(in: language), isWord: true) : word)

        capitalizesNextWord = false
        previousWord = word.text
    }

    private mutating func removeHesitation() {
        let before = kept.last?.isWord == false ? kept.removeLast().text : ""
        let after = takeSeparator()
        let isAtStart = !kept.contains(where: \.isWord)
        let isAtEnd = !segments[index...].contains(where: \.isWord)
        let separator = joinedSeparator(before, after, isAtStart: isAtStart, isAtEnd: isAtEnd)

        if !separator.isEmpty {
            kept.append(TextSegment(text: separator, isWord: false))
        }

        if isAtStart || separator.contains(where: { LightModeRules.endsSentence($0, in: language) }) {
            capitalizesNextWord = true
        }
    }

    private mutating func takeSeparator() -> String {
        guard index < segments.count, !segments[index].isWord else { return "" }

        let separator = segments[index].text
        index += 1

        return separator
    }

    private func joinedSeparator(_ before: String, _ after: String, isAtStart: Bool, isAtEnd: Bool) -> String {
        guard !isAtStart else { return "" }

        let isFraming = LightModeRules.framingMarks.contains
        let trimmedBefore = before.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAfter = after.trimmingCharacters(in: .whitespacesAndNewlines)
        let left = String(trimmedBefore.reversed().drop(while: isFraming).reversed())
        let right = String(trimmedAfter.drop(while: isFraming))
        let core = left.isEmpty ? right : left
        let gap = (before + after).contains("\n") ? "\n" : (language.separatesWordsWithSpaces ? " " : "")

        return isAtEnd ? core : core + gap
    }
}
