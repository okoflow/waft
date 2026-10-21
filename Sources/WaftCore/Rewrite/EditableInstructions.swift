package struct EditableInstructions<Subject: InstructionsSubject>: Codable, Equatable, Sendable {
    private var custom: [String: String] = [:]

    package func editableText(for subject: Subject) -> String {
        guard let text = custom[subject.rawValue] else { return subject.defaultInstructions }

        return text
    }

    package func isCustomized(_ subject: Subject) -> Bool {
        custom[subject.rawValue] != nil
    }

    package mutating func set(_ text: String, for subject: Subject) {
        custom[subject.rawValue] = text == subject.defaultInstructions ? nil : text
    }

    package mutating func reset(_ subject: Subject) {
        custom[subject.rawValue] = nil
    }

    func text(for subject: Subject) -> String {
        guard let text = custom[subject.rawValue], !text.isBlank else { return subject.defaultInstructions }

        return text
    }
}
