import WaftCore

final class FakeTextInserter: TextInserter {
    struct Insertion {
        let text: String
        let app: String?
    }

    private(set) var insertions: [Insertion] = []
    private(set) var copyCount = 0

    private let outcome: InsertionOutcome
    private let copiedSelection: String?

    init(_ outcome: InsertionOutcome = .pasted, copying copiedSelection: String? = nil) {
        self.outcome = outcome
        self.copiedSelection = copiedSelection
    }

    func insert(_ text: String, into target: FocusTarget, releasing _: PushToTalkKey) -> InsertionOutcome {
        insertions.append(Insertion(text: text, app: target.bundleIdentifier))

        return outcome
    }

    func copySelection(from _: FocusTarget) -> String? {
        copyCount += 1

        return copiedSelection
    }

    func waitUntilIdle() {}
}
