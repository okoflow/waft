import Foundation

enum RewriteValidator {
    private typealias Wrapper = (open: String, close: String)

    private static let quotes: [Wrapper] = [("\"", "\""), ("«", "»")]
    private static let cleanupWrappers: [Wrapper] = [(PromptTag.transcript.open, PromptTag.transcript.close)] + quotes
    private static let editWrappers: [Wrapper] = [(PromptTag.text.open, PromptTag.text.close)] + quotes

    static func validated(_ answer: String, for request: RewriteRequest) throws(RewriteError) -> String {
        switch request.kind {
        case let .cleanup(_, target):
            try validatedCleanup(answer, of: request.text, language: request.language, target: target)
        case .custom:
            try validatedCustom(answer, of: request.text)
        case let .edit(selection):
            try validatedEdit(answer, of: selection)
        case .text:
            try validatedText(answer, of: request.text)
        }
    }

    private static func validatedCleanup(
        _ answer: String,
        of transcript: String,
        language: Language,
        target: Language?,
    ) throws(RewriteError) -> String {
        let text = unwrapped(answer, input: transcript, from: cleanupWrappers)
        guard !text.isEmpty, text.count <= maximumLength(for: transcript, language: language, target: target) else {
            throw .unreadableResponse
        }

        let scripts = expectedScripts(for: transcript, language: language, target: target)

        if let script = WritingScript.dominant(in: text), !scripts.contains(script) {
            throw .unreadableResponse
        }

        return text
    }

    private static func validatedCustom(_ answer: String, of transcript: String) throws(RewriteError) -> String {
        let text = unwrapped(answer, input: transcript, from: cleanupWrappers)
        guard !text.isEmpty, text.count <= max(transcript.count * 10, 600) else { throw .unreadableResponse }

        return text
    }

    private static func validatedEdit(_ answer: String, of selection: String) throws(RewriteError) -> String {
        let text = unwrapped(answer, input: selection, from: editWrappers)
        guard !text.isEmpty else { throw .unreadableResponse }

        return text
    }

    private static func validatedText(_ answer: String, of input: String) throws(RewriteError) -> String {
        let text = unwrapped(answer, input: input, from: editWrappers)
        guard !text.isEmpty, text.count <= input.count * 5 + 200 else { throw .unreadableResponse }

        return text
    }

    private static func maximumLength(for input: String, language: Language, target: Language?) -> Int {
        let translatesCompactScript = target != nil && language.scripts.contains(where: \.isCompact)

        return input.count * (translatesCompactScript ? 5 : 3) + 60
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
