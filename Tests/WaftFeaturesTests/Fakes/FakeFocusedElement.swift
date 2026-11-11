import WaftCore

nonisolated struct FakeFocusedElement: FocusedElement {
    let selectedText: String?
    var hasEmptySelection = false
    var secureFieldState = SecureFieldState.notSecure
    let characterBeforeCaret: Character? = nil

    func isDifferent(from _: any FocusedElement) -> Bool {
        false
    }
}
