import Testing
import WaftCore

struct InsertionDecisionTests {
    @Test(arguments: [
        (true, true, true, false, InsertionDecision.skip(.secureField)),
        (true, false, false, true, .skip(.secureField)),
        (false, false, false, true, .skip(.noAccessibility)),
        (false, true, false, true, .skip(.focusChanged)),
        (false, true, true, true, .skip(.keyHeld)),
        (false, true, true, false, .paste),
    ])
    func `decides by order of precedence`(
        isSecureField: Bool,
        canPostKeys: Bool,
        isFocusOnTarget: Bool,
        isKeyHeld: Bool,
        expected: InsertionDecision,
    ) {
        let decision = InsertionDecision.decide(
            isSecureField: isSecureField,
            canPostKeys: canPostKeys,
            isFocusOnTarget: isFocusOnTarget,
            isKeyHeld: isKeyHeld,
        )

        #expect(decision == expected)
    }
}
