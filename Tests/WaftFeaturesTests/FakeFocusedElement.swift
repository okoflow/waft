import WaftCore

nonisolated struct FakeFocusedElement: FocusedElement {
    let selectedText: String?
    var hasEmptySelection = false
    let isSecureTextField = false
    let characterBeforeCaret: Character? = nil

    func compare(with _: any FocusedElement) -> FocusComparison {
        .unknown
    }
}
