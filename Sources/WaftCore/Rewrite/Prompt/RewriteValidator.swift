import Foundation

enum RewriteValidator {
    private typealias Wrapper = (open: String, close: String)

    private static let quotes: [Wrapper] = [("\"", "\""), ("«", "»")]
    private static let openingQuotes: Set<Character> = ["\"", "«", "„", "“", "‘", "「"]
    private static let shortestMeasuredCleanup = 200
    private static let shortestCleanupShare = 0.4

    static func validated(_ answer: String, for request: RewriteRequest) throws(RewriteError) -> String {
        let text = unwrapped(answer, from: wrappers(for: request))
        guard !unwrapped(text, from: quotes).isEmpty,
              text.count <= maximumLength(for: request),
              text.count >= minimumLength(for: request) else {
            throw .unreadableResponse
        }
        guard case let .cleanup(_, language, target, _) = request.kind,
              let script = WritingScript.dominant(in: text) else { return text }
        guard expectedScripts(for: request.text, language: language, target: target).contains(script) else {
            throw .unreadableResponse
        }

        return text
    }

    private static func wrappers(for request: RewriteRequest) -> [Wrapper] {
        switch request.kind {
        case .cleanup, .custom: addedTags([.transcript, .reply], to: request.text) + addedQuotes(to: request.text)
        case let .edit(selection, _): addedTags([.text, .reply], to: selection)
        case .text: addedTags([.text, .reply], to: request.text) + addedQuotes(to: request.text)
        }
    }

    private static func addedTags(_ tags: [PromptTag], to input: String) -> [Wrapper] {
        tags.filter { !input.hasPrefix($0.open) }.map { ($0.open, $0.close) }
    }

    private static func addedQuotes(to input: String) -> [Wrapper] {
        guard let first = input.first(where: { !$0.isWhitespace }), openingQuotes.contains(first) else { return quotes }

        return []
    }

    private static func maximumLength(for request: RewriteRequest) -> Int {
        let length = request.text.count

        return switch request.kind {
        case let .cleanup(_, language, target, _): length * cleanupLengthFactor(target: target, language: language) + 60
        case .custom: max(length * 10, 600)
        case .edit: .max
        case .text: length * 5 + 200
        }
    }

    private static func minimumLength(for request: RewriteRequest) -> Int {
        guard case .cleanup(_, _, nil, _) = request.kind, request.text.count >= shortestMeasuredCleanup else { return 0 }

        return Int((Double(request.text.count) * shortestCleanupShare).rounded(.up))
    }

    private static func cleanupLengthFactor(target: Language?, language: Language) -> Int {
        guard target != nil, language.scripts.contains(where: \.isCompact) else { return 3 }

        return 5
    }

    private static func expectedScripts(for input: String, language: Language, target: Language?) -> Set<WritingScript> {
        if let target {
            return target.scripts
        }

        guard let transcriptScript = WritingScript.dominant(in: input) else { return language.scripts }

        return language.scripts.union([transcriptScript])
    }

    private static func unwrapped(_ answer: String, from wrappers: [Wrapper]) -> String {
        var text = answer.trimmingCharacters(in: .whitespacesAndNewlines)

        while let wrapper = wrappers.first(where: { isWrapped(text, in: $0) }) {
            text = String(text.dropFirst(wrapper.open.count).dropLast(wrapper.close.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return text
    }

    private static func isWrapped(_ text: String, in wrapper: Wrapper) -> Bool {
        guard text.hasPrefix(wrapper.open),
              text.hasSuffix(wrapper.close),
              text.count >= wrapper.open.count + wrapper.close.count else {
            return false
        }

        let inner = text.dropFirst(wrapper.open.count).dropLast(wrapper.close.count)

        return [wrapper.open, wrapper.close].allSatisfy { !inner.contains($0) }
    }
}
