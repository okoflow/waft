import WaftCore

extension FocusTarget {
    static let notes = app("com.example.notes")
    static let notesWithSelection = app("com.example.notes", element: FakeFocusedElement(selectedText: "Meeting at noon"))

    static let passwordField = app(
        "com.example.passwords",
        element: FakeFocusedElement(selectedText: nil, secureFieldState: .secure),
    )

    static func app(_ bundleIdentifier: String, element: (any FocusedElement)? = nil) -> FocusTarget {
        FocusTarget(processID: 1, bundleIdentifier: bundleIdentifier, element: element, secureInput: .nobody)
    }
}
