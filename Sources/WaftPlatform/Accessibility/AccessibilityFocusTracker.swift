package import WaftCore
import AppKit
import ApplicationServices

@MainActor
package final class AccessibilityFocusTracker: FocusTracker {
    package init() {}

    package func currentFocus() -> FocusTarget {
        let app = NSWorkspace.shared.frontmostApplication
        let element = AXIsProcessTrusted() ? AccessibilityElement.focusedElement() : nil

        return FocusTarget(processID: app?.processIdentifier, bundleIdentifier: app?.bundleIdentifier, element: element)
    }
}
