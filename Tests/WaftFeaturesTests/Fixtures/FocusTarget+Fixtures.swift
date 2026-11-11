import WaftCore

extension FocusTarget {
    static let notes = app("com.example.notes")
    static let notesWithSelection = app("com.example.notes", element: FakeFocusedElement(selectedText: "Meeting at noon"))

    static func app(_ bundleIdentifier: String, element: (any FocusedElement)? = nil) -> FocusTarget {
        FocusTarget(processID: 1, bundleIdentifier: bundleIdentifier, element: element, secureInput: .nobody)
    }
}
