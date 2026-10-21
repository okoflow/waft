import WaftCore

extension RewriteRequest {
    var textTask: TextTask? {
        guard case let .text(task, _) = kind else { return nil }

        return task
    }

    var textInstructions: String? {
        guard case let .text(_, instructions) = kind else { return nil }

        return instructions
    }
}
