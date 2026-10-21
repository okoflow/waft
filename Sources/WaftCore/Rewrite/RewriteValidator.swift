import Foundation

enum RewriteValidator {
    private typealias Wrapper = (open: String, close: String)

    private static let quotes: [Wrapper] = [("\"", "\""), ("«", "»")]
    private static let cleanupWrappers: [Wrapper] = [(PromptTag.transcript.open, PromptTag.transcript.close)] + quotes
    private static let editWrappers: [Wrapper] = [(PromptTag.text.open, PromptTag.text.close)] + quotes

    static func validated(_ answer: String, for request: RewriteRequest) throws(RewriteError) -> String {
        let (text, maximumLength) = unwrapped(answer, for: request)
        guard !text.isEmpty, text.count <= maximumLength else { throw .unreadableResponse }
        guard case let .cleanup(_, target) = request.kind, let script = WritingScript.dominant(in: text) else { return text }
        guard expectedScripts(for: request.text, language: request.language, target: target).contains(script) else {
            throw .unreadableResponse
        }

        return text
    }

    private static func unwrapped(_ answer: String, for request: RewriteRequest) -> (text: String, maximumLength: Int) {
        let input = request.text

        switch request.kind {
        case let .cleanup(_, target):
            let lengthFactor = cleanupLengthFactor(target: target, language: request.language)

            return (unwrapped(answer, input: input, from: cleanupWrappers), input.count * lengthFactor + 60)

        case .custom:
            return (unwrapped(answer, input: input, from: cleanupWrappers), max(input.count * 10, 600))

        case let .edit(selection):
            return (unwrapped(answer, input: selection, from: editWrappers), .max)

        case .text:
            return (unwrapped(answer, input: input, from: editWrappers), input.count * 5 + 200)
        }
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

        for wrapper in applicable where isWrapped(text, in: wrapper) {
            text = String(text.dropFirst(wrapper.open.count).dropLast(wrapper.close.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return text
    }

    private static func isWrapped(_ text: String, in wrapper: Wrapper) -> Bool {
        guard text.hasPrefix(wrapper.open), text.hasSuffix(wrapper.close),
              text.count >= wrapper.open.count + wrapper.close.count else {
            return false
        }

        let inner = text.dropFirst(wrapper.open.count).dropLast(wrapper.close.count)

        return [wrapper.open, wrapper.close].allSatisfy { !inner.contains($0) }
    }
}
