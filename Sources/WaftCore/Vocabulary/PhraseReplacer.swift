import Foundation

struct PhraseReplacer {
    struct Replacement {
        let phrase: String
        let replacement: String
    }

    private struct Rule {
        let segments: [TextSegment]
        let leadingMarks: String
        let replacement: String
    }

    private struct Match {
        let rule: Rule
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

    private static func rule(for replacement: Replacement, in language: Language) -> Rule? {
        let segments = TextSegment.split(replacement.phrase.trimmingCharacters(in: .whitespacesAndNewlines))
        guard let first = segments.first, first.isWord else { return nil }

        let normalized = segments.map { normalizedWord($0, in: language) }
        let marks = leadingMarks(of: replacement.replacement)

        return Rule(
            segments: normalized,
            leadingMarks: marks,
            replacement: String(replacement.replacement.dropFirst(marks.count)),
        )
    }

    private static func leadingMarks(of replacement: String) -> String {
        let segments = TextSegment.split(replacement)
        guard let first = segments.first, !first.isWord, segments.count > 1 else { return "" }

        return first.text
    }

    private static func normalizedWord(_ segment: TextSegment, in language: Language) -> TextSegment {
        guard segment.isWord else { return segment }

        return TextSegment(text: segment.text.normalizedWord(in: language), isWord: true)
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
                result += replacement(of: match.rule, after: result) + match.rest
                index = match.lastSegment + 1

                continue
            }

            result += segments[index].text
            index += 1
        }

        return result
    }

    private func replacement(of rule: Rule, after written: String) -> String {
        guard !rule.leadingMarks.isEmpty, written.hasSuffix(rule.leadingMarks) else {
            return rule.leadingMarks + rule.replacement
        }

        return rule.replacement
    }

    private func match(at start: Int, in segments: [TextSegment]) -> Match? {
        rules.lazy.compactMap { match($0, at: start, in: segments) }.first
    }

    private func match(_ rule: Rule, at start: Int, in segments: [TextSegment]) -> Match? {
        let end = start + rule.segments.count - 1
        guard end < segments.count, let last = rule.segments.last else { return nil }

        let leadingSegmentsMatch = zip(segments[start ..< end], rule.segments).allSatisfy(isMatch)
        guard leadingSegmentsMatch, let rest = unmatchedRest(of: segments[end], after: last) else { return nil }

        return Match(rule: rule, lastSegment: end, rest: rest)
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
