import WaftCore

nonisolated struct FakeFocusedElement: FocusedElement {
    let selectedText: String?
    var hasEmptySelection = false
    let isSecureTextField = false
    let characterBeforeCaret: Character? = nil

    func isDifferent(from _: any FocusedElement) -> Bool {
        false
    }
}
