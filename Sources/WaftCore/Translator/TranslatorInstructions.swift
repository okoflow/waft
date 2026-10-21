package struct TranslatorInstructions: Codable, Equatable, Sendable {
    private var custom: [String: String] = [:]

    package func editableText(for kind: TextTask.Kind) -> String {
        guard let text = custom[kind.rawValue] else { return RewritePrompt.defaultTextInstructions(for: kind) }

        return text
    }

    package func isCustomized(_ kind: TextTask.Kind) -> Bool {
        custom[kind.rawValue] != nil
    }

    package mutating func set(_ text: String, for kind: TextTask.Kind) {
        custom[kind.rawValue] = text == RewritePrompt.defaultTextInstructions(for: kind) ? nil : text
    }

    package mutating func reset(_ kind: TextTask.Kind) {
        custom[kind.rawValue] = nil
    }

    func text(for kind: TextTask.Kind) -> String {
        guard let text = custom[kind.rawValue], !text.isBlank else {
            return RewritePrompt.defaultTextInstructions(for: kind)
        }

        return text
    }
}
