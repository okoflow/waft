import WaftCore

extension RewriteRequest {
    var textTask: TextTask? {
        guard case let .text(task, _) = kind else { return nil }

        return task
    }

    var rephrases: Bool {
        guard case let .text(_, rephrases) = kind else { return false }

        return rephrases
    }
}
