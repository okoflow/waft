import WaftCore

final class FakeFocusTracker: FocusTracker {
    var focus: FocusTarget

    init(_ focus: FocusTarget = .notes) {
        self.focus = focus
    }

    func currentFocus() -> FocusTarget {
        focus
    }
}
