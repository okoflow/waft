package struct ModeInstructions: Codable, Equatable, Sendable {
    private var custom: [String: String] = [:]

    package init() {}

    package func editableText(for mode: Mode) -> String {
        guard let text = custom[mode.storageKey] else { return RewritePrompt.defaultInstructions(for: mode) }

        return text
    }

    package func isCustomized(_ mode: Mode) -> Bool {
        custom[mode.storageKey] != nil
    }

    package mutating func set(_ text: String, for mode: Mode) {
        custom[mode.storageKey] = text == RewritePrompt.defaultInstructions(for: mode) ? nil : text
    }

    package mutating func reset(_ mode: Mode) {
        custom[mode.storageKey] = nil
    }

    func text(for mode: Mode) -> String {
        guard let text = custom[mode.storageKey], !text.isBlank else {
            return RewritePrompt.defaultInstructions(for: mode)
        }

        return text
    }
}
