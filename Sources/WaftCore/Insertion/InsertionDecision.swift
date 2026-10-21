package enum InsertionDecision: Equatable, Sendable {
    case paste
    case skip(InsertionSkipReason)

    package static func decide(
        isSecureField: Bool,
        canPostKeys: Bool,
        isFocusOnTarget: Bool,
        isKeyHeld: Bool,
    ) -> InsertionDecision {
        guard !isSecureField else { return .skip(.secureField) }
        guard canPostKeys else { return .skip(.noAccessibility) }
        guard isFocusOnTarget else { return .skip(.focusChanged) }
        guard !isKeyHeld else { return .skip(.keyHeld) }

        return .paste
    }
}
