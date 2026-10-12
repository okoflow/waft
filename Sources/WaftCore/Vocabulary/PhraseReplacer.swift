import Foundation

struct PhraseReplacer {
    struct Replacement {
        let phrase: String
        let replacement: String
    }

    private struct Rule {
        let segments: [TextSegment]
        let replacement: String
    }

    private struct Match {
        let replacement: String
        let lastSegment: Int
        let rest: String
    }

    private let rules: [Rule]
    private let language: Language

    init(_ replacements: [Replacement], language: Language) {
        rules = replacements
            .compactMap { Self.rule(for: $0, in: language) }
            .sorted { $0.segments.count > $1.segments.count }
        self.language = language
    }

    static func words(of text: String, in language: Language) -> [String] {
        TextSegment.split(text).filter(\.isWord).map { $0.text.normalizedWord(in: language) }
    }

    private static func rule(for replacement: Replacement, in language: Language) -> Rule? {
        let segments = TextSegment.split(replacement.phrase.trimmingCharacters(in: .whitespacesAndNewlines))
        guard let first = segments.first, first.isWord else { return nil }

        let normalized = segments.map { segment in
            segment.isWord ? TextSegment(text: segment.text.normalizedWord(in: language), isWord: true) : segment
        }

        return Rule(segments: normalized, replacement: replacement.replacement)
    }

    private static func koreanParticle(after word: String, in spoken: String) -> String? {
        guard spoken.hasPrefix(word), let last = word.unicodeScalars.last, isHangulSyllable(last) else { return nil }

        let rest = String(spoken.dropFirst(word.count))
        guard (1 ... 2).contains(rest.count), rest.unicodeScalars.allSatisfy(isHangulSyllable) else { return nil }

        return rest
    }

    private static func isHangulSyllable(_ scalar: Unicode.Scalar) -> Bool {
        (0xAC00 ... 0xD7AF).contains(scalar.value)
    }

    func apply(to text: String) -> String {
        guard !rules.isEmpty else { return text }

        let segments = TextSegment.split(text)
        var result = ""
        var index = 0

        while index < segments.count {
            if segments[index].isWord, let match = match(at: index, in: segments) {
                result += match.replacement + match.rest
                index = match.lastSegment + 1
            } else {
                result += segments[index].text
                index += 1
            }
        }

        return result
    }

    private func match(at start: Int, in segments: [TextSegment]) -> Match? {
        rules.lazy.compactMap { match($0, at: start, in: segments) }.first
    }

    private func match(_ rule: Rule, at start: Int, in segments: [TextSegment]) -> Match? {
        let end = start + rule.segments.count - 1
        guard end < segments.count, let last = rule.segments.last else { return nil }

        let leadingSegmentsMatch = zip(segments[start ..< end], rule.segments).allSatisfy(isMatch)
        guard leadingSegmentsMatch, let rest = unmatchedRest(of: segments[end], after: last) else { return nil }

        return Match(replacement: rule.replacement, lastSegment: end, rest: rest)
    }

    private func isMatch(_ segment: TextSegment, _ expected: TextSegment) -> Bool {
        guard !expected.isWord else { return segment.text.normalizedWord(in: language) == expected.text }
        guard !expected.text.allSatisfy(\.isWhitespace) else { return segment.text.allSatisfy(\.isWhitespace) }

        return segment.text == expected.text
    }

    private func unmatchedRest(of segment: TextSegment, after expected: TextSegment) -> String? {
        guard expected.isWord else { return unmatchedRest(ofSeparator: segment.text, after: expected.text) }

        return unmatchedRest(ofWord: segment.text, after: expected.text)
    }

    private func unmatchedRest(ofWord word: String, after expected: String) -> String? {
        let spoken = word.normalizedWord(in: language)
        guard spoken != expected else { return "" }
        guard let particle = Self.koreanParticle(after: expected, in: spoken) else { return nil }

        return String(word.suffix(particle.count))
    }

    private func unmatchedRest(ofSeparator separator: String, after expected: String) -> String? {
        guard separator.hasPrefix(expected) else { return nil }

        return String(separator.dropFirst(expected.count))
    }
}
