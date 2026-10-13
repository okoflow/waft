import WaftCore

final class FakeTextInserter: TextInserter {
    struct Insertion {
        let text: String
        let app: String?
    }

    private(set) var insertions: [Insertion] = []

    private let outcome: InsertionOutcome

    init(_ outcome: InsertionOutcome = .pasted) {
        self.outcome = outcome
    }

    func insert(_ text: String, into target: FocusTarget, releasing _: PushToTalkKey) -> InsertionOutcome {
        insertions.append(Insertion(text: text, app: target.bundleIdentifier))

        return outcome
    }

    func waitUntilIdle() {}
}
