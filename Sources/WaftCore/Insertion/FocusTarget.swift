package struct FocusTarget: Sendable {
    package let bundleIdentifier: String?
    package let element: (any FocusedElement)?

    private let processID: Int32?

    package var appDescription: String {
        guard let bundleIdentifier else { return "an unknown app" }

        return bundleIdentifier
    }

    package init(processID: Int32?, bundleIdentifier: String?, element: (any FocusedElement)?) {
        self.processID = processID
        self.bundleIdentifier = bundleIdentifier
        self.element = element
    }

    package func isSameFocus(as current: FocusTarget) -> Bool {
        guard let processID, processID == current.processID else { return false }
        guard let element, let currentElement = current.element else { return true }

        return element.compare(with: currentElement) != .different
    }
}
