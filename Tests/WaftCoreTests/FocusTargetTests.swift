import Testing
import WaftCore

struct FocusTargetTests {
    @Test(arguments: [(Int32?.none, Int32?.some(1)), (1, 2), (nil, nil)])
    func `treats a different or unknown app as a focus change`(saved: Int32?, current: Int32?) {
        let target = FocusTarget(processID: saved, bundleIdentifier: "com.apple.mail", element: nil)
        let now = FocusTarget(processID: current, bundleIdentifier: "com.apple.mail", element: nil)

        #expect(!target.isSameFocus(as: now))
    }

    @Test(arguments: [(FocusComparison?.some(.different), FocusComparison?.none), (nil, .different), (nil, nil)])
    func `trusts the same app when an element is unknown`(saved: FocusComparison?, current: FocusComparison?) {
        let target = FocusTarget(processID: 7, bundleIdentifier: nil, element: saved.map(FakeFocusedElement.init))
        let now = FocusTarget(processID: 7, bundleIdentifier: nil, element: current.map(FakeFocusedElement.init))

        #expect(target.isSameFocus(as: now))
    }

    @Test(arguments: [(FocusComparison.same, true), (.unknown, true), (.different, false)])
    func `compares the focused elements in the same app`(comparison: FocusComparison, isSame: Bool) {
        let target = FocusTarget(processID: 7, bundleIdentifier: nil, element: FakeFocusedElement(comparison: comparison))
        let now = FocusTarget(processID: 7, bundleIdentifier: nil, element: FakeFocusedElement(comparison: .same))

        #expect(target.isSameFocus(as: now) == isSame)
    }

    @Test(arguments: [("com.apple.mail", "com.apple.mail"), (nil, "an unknown app")])
    func `describes the app`(bundleIdentifier: String?, description: String) {
        #expect(FocusTarget(processID: 1, bundleIdentifier: bundleIdentifier, element: nil).appDescription == description)
    }
}

private struct FakeFocusedElement: FocusedElement {
    let comparison: FocusComparison
    let isSecureTextField = false
    let characterBeforeCaret: Character? = nil
    let selectedText: String? = nil

    func compare(with _: any FocusedElement) -> FocusComparison {
        comparison
    }
}
