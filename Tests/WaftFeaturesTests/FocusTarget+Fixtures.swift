import WaftCore

extension FocusTarget {
    static let notes = app("com.example.notes")

    static func app(_ bundleIdentifier: String, element: (any FocusedElement)? = nil) -> FocusTarget {
        FocusTarget(processID: 1, bundleIdentifier: bundleIdentifier, element: element)
    }
}
