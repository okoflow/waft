import Foundation

enum RewriteValidator {
    private typealias Wrapper = (open: String, close: String)

    private static let quotes: [Wrapper] = [("\"", "\""), ("«", "»")]
    private static let cleanupWrappers: [Wrapper] = [(PromptTag.transcript.open, PromptTag.transcript.close)] + quotes
    private static let editWrappers: [Wrapper] = [(PromptTag.text.open, PromptTag.text.close)] + quotes
    private static let shortestMeasuredCleanup = 200
    private static let shortestCleanupShare = 0.4

    static func validated(_ answer: String, for request: RewriteRequest) throws(RewriteError) -> String {
        let text = unwrapped(answer, for: request)
        guard !text.isEmpty, text.count <= maximumLength(for: request), text.count >= minimumLength(for: request) else {
            throw .unreadableResponse
        }
        guard case let .cleanup(_, target, _) = request.kind, let script = WritingScript.dominant(in: text) else { return text }
        guard expectedScripts(for: request.text, language: request.language, target: target).contains(script) else {
            throw .unreadableResponse
        }

        return text
    }

    private static func unwrapped(_ answer: String, for request: RewriteRequest) -> String {
        switch request.kind {
        case .cleanup, .custom: unwrapped(answer, input: request.text, from: cleanupWrappers)
        case let .edit(selection): unwrapped(answer, input: selection, from: editWrappers)
        case .text: unwrapped(answer, input: request.text, from: editWrappers)
        }
    }

    private static func maximumLength(for request: RewriteRequest) -> Int {
        let length = request.text.count

        return switch request.kind {
        case let .cleanup(_, target, _): length * cleanupLengthFactor(target: target, language: request.language) + 60
        case .custom: max(length * 10, 600)
        case .edit: .max
        case .text: length * 5 + 200
        }
    }

    private static func minimumLength(for request: RewriteRequest) -> Int {
        guard case .cleanup(_, nil, _) = request.kind, request.text.count >= shortestMeasuredCleanup else { return 0 }

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

    private static func unwrapped(_ answer: String, input: String, from wrappers: [Wrapper]) -> String {
        let applicable = wrappers.filter { !input.hasPrefix($0.open) }

        var text = answer.trimmingCharacters(in: .whitespacesAndNewlines)

        while let wrapper = applicable.first(where: { isWrapped(text, in: $0) }) {
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
