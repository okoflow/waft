package protocol FocusedElement: Sendable {
    var isSecureTextField: Bool { get }
    var characterBeforeCaret: Character? { get }
    var selectedText: String? { get }
    var hasEmptySelection: Bool { get }

    func compare(with other: any FocusedElement) -> FocusComparison
}
