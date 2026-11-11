package struct FocusTarget: Sendable {
    package let bundleIdentifier: String?
    package let element: (any FocusedElement)?
    package let isSecureField: Bool

    private let processID: Int32?

    package var appDescription: String {
        guard let bundleIdentifier else { return "an unknown app" }

        return bundleIdentifier
    }

    package init(
        processID: Int32?,
        bundleIdentifier: String?,
        element: (any FocusedElement)?,
        secureInput holder: SecureInputHolder,
    ) {
        self.processID = processID
        self.bundleIdentifier = bundleIdentifier
        self.element = element
        isSecureField = Self.isSecureField(element, of: processID, secureInput: holder)
    }

    private static func isSecureField(
        _ element: (any FocusedElement)?,
        of processID: Int32?,
        secureInput holder: SecureInputHolder,
    ) -> Bool {
        guard let element else { return mayHoldSecureInput(processID, holder) }

        return switch element.secureFieldState {
        case .secure: true
        case .notSecure: false
        case .unreadable: mayHoldSecureInput(processID, holder)
        }
    }

    private static func mayHoldSecureInput(_ processID: Int32?, _ holder: SecureInputHolder) -> Bool {
        switch holder {
        case .nobody: false
        case .unknown: true
        case let .process(holderID): holderID == processID
        }
    }

    package func isSameFocus(as current: FocusTarget) -> Bool {
        guard let processID, processID == current.processID else { return false }
        guard let element, let currentElement = current.element else { return true }

        return !element.isDifferent(from: currentElement)
    }
}
