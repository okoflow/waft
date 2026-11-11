import Testing
import WaftCore

struct FocusTargetTests {
    private static func differentElement(if isPresent: Bool) -> FakeFocusedElement? {
        guard isPresent else { return nil }

        return FakeFocusedElement(differs: true)
    }

    private static func target(
        processID: Int32?,
        bundleIdentifier: String? = nil,
        element: FakeFocusedElement? = nil,
        secureInput holder: SecureInputHolder = .nobody,
    ) -> FocusTarget {
        FocusTarget(processID: processID, bundleIdentifier: bundleIdentifier, element: element, secureInput: holder)
    }

    @Test(arguments: [(Int32?.none, Int32?.some(1)), (1, 2), (nil, nil)])
    func `treats a different or unknown app as a focus change`(saved: Int32?, current: Int32?) {
        let target = Self.target(processID: saved)
        let now = Self.target(processID: current)

        #expect(!target.isSameFocus(as: now))
    }

    @Test(arguments: [(true, false), (false, true), (false, false)])
    func `trusts the same app when an element is unknown`(hasSavedElement: Bool, hasCurrentElement: Bool) {
        let target = Self.target(processID: 7, element: Self.differentElement(if: hasSavedElement))
        let now = Self.target(processID: 7, element: Self.differentElement(if: hasCurrentElement))

        #expect(target.isSameFocus(as: now))
    }

    @Test(arguments: [(false, true), (true, false)])
    func `compares the focused elements in the same app`(differs: Bool, isSame: Bool) {
        let target = Self.target(processID: 7, element: FakeFocusedElement(differs: differs))
        let now = Self.target(processID: 7, element: FakeFocusedElement(differs: false))

        #expect(target.isSameFocus(as: now) == isSame)
    }

    @Test(arguments: [(true, SecureInputHolder.nobody), (false, .process(7)), (true, .process(8))])
    func `takes a readable field's own word on whether it is a password field`(isSecure: Bool, holder: SecureInputHolder) {
        let element = FakeFocusedElement(differs: false, secureFieldState: isSecure ? .secure : .notSecure)
        let target = Self.target(processID: 7, element: element, secureInput: holder)

        #expect(target.isSecureField == isSecure)
    }

    @Test(arguments: [
        (Int32?.some(7), SecureInputHolder.nobody, false),
        (7, .process(8), false),
        (7, .process(7), true),
        (7, .unknown, true),
        (nil, .process(7), false),
    ])
    func `treats a field that did not answer as a password field only while its own app may hold secure input`(
        processID: Int32?,
        holder: SecureInputHolder,
        isSecure: Bool,
    ) {
        let element = FakeFocusedElement(differs: false, secureFieldState: .unreadable)
        let target = Self.target(processID: processID, element: element, secureInput: holder)

        #expect(target.isSecureField == isSecure)
    }

    @Test(arguments: [
        (Int32?.some(7), SecureInputHolder.nobody, false),
        (7, .process(8), false),
        (7, .process(7), true),
        (7, .unknown, true),
        (nil, .process(7), false),
    ])
    func `treats an unreadable field as a password field only while its own app may hold secure input`(
        processID: Int32?,
        holder: SecureInputHolder,
        isSecure: Bool,
    ) {
        let target = Self.target(processID: processID, secureInput: holder)

        #expect(target.isSecureField == isSecure)
    }

    @Test(arguments: [("com.apple.mail", "com.apple.mail"), (nil, "an unknown app")])
    func `describes the app`(bundleIdentifier: String?, description: String) {
        #expect(Self.target(processID: 1, bundleIdentifier: bundleIdentifier).appDescription == description)
    }
}

private struct FakeFocusedElement: FocusedElement {
    let differs: Bool
    var secureFieldState = SecureFieldState.notSecure
    let characterBeforeCaret: Character? = nil
    let selectedText: String? = nil
    let hasEmptySelection = false

    func isDifferent(from _: any FocusedElement) -> Bool {
        differs
    }
}
