@MainActor
package protocol TextInserter: AnyObject {
    func insert(_ text: String, into target: FocusTarget, releasing key: PushToTalkKey) async -> InsertionOutcome
    func copySelection(from target: FocusTarget) async -> String?
    func waitUntilIdle() async
}
