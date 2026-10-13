import WaftCore

nonisolated struct FakeKeyboardState: KeyboardState {
    let holdsKeys: Bool

    func isHeld(_: PushToTalkKey) -> Bool {
        holdsKeys
    }
}
