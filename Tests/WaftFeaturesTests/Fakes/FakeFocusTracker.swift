import Foundation
import WaftCore

final class FakeFocusTracker: FocusTracker {
    var focus: FocusTarget
    var lookupDuration: TimeInterval = 0

    init(_ focus: FocusTarget = .notes) {
        self.focus = focus
    }

    func currentFocus() -> FocusTarget {
        Thread.sleep(forTimeInterval: lookupDuration)

        return focus
    }
}
