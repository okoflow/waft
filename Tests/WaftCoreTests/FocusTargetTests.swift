import Testing
import WaftCore

struct FocusTargetTests {
    private static func differentElement(if isPresent: Bool) -> FakeFocusedElement? {
        guard isPresent else { return nil }

        return FakeFocusedElement(differs: true)
    }

    @Test(arguments: [(Int32?.none, Int32?.some(1)), (1, 2), (nil, nil)])
    func `treats a different or unknown app as a focus change`(saved: Int32?, current: Int32?) {
        let target = FocusTarget(processID: saved, bundleIdentifier: "com.apple.mail", element: nil)
        let now = FocusTarget(processID: current, bundleIdentifier: "com.apple.mail", element: nil)

        #expect(!target.isSameFocus(as: now))
    }

    @Test(arguments: [(true, false), (false, true), (false, false)])
    func `trusts the same app when an element is unknown`(hasSavedElement: Bool, hasCurrentElement: Bool) {
        let target = FocusTarget(processID: 7, bundleIdentifier: nil, element: Self.differentElement(if: hasSavedElement))
        let now = FocusTarget(processID: 7, bundleIdentifier: nil, element: Self.differentElement(if: hasCurrentElement))

        #expect(target.isSameFocus(as: now))
    }

    @Test(arguments: [(false, true), (true, false)])
    func `compares the focused elements in the same app`(differs: Bool, isSame: Bool) {
        let target = FocusTarget(processID: 7, bundleIdentifier: nil, element: FakeFocusedElement(differs: differs))
        let now = FocusTarget(processID: 7, bundleIdentifier: nil, element: FakeFocusedElement(differs: false))

        #expect(target.isSameFocus(as: now) == isSame)
    }

    @Test(arguments: [("com.apple.mail", "com.apple.mail"), (nil, "an unknown app")])
    func `describes the app`(bundleIdentifier: String?, description: String) {
        #expect(FocusTarget(processID: 1, bundleIdentifier: bundleIdentifier, element: nil).appDescription == description)
    }
}

private struct FakeFocusedElement: FocusedElement {
    let differs: Bool
    let isSecureTextField = false
    let characterBeforeCaret: Character? = nil
    let selectedText: String? = nil
    let hasEmptySelection = false

    func isDifferent(from _: any FocusedElement) -> Bool {
        differs
    }
}
