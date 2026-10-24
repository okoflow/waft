import AppKit

extension NSWindow {
    func clickLeavesEditedText(at location: NSPoint) -> Bool {
        guard firstResponder is NSText, let hit = contentView?.hitTest(location) else { return false }

        return !hit.isTextInput
    }
}

extension NSView {
    fileprivate var isTextInput: Bool {
        sequence(first: self, next: \.superview).contains(where: \.isTextControl)
    }

    private var isTextControl: Bool {
        switch self {
        case is NSTextView, is NSTextField: true
        case let scrollView as NSScrollView: scrollView.documentView is NSTextView
        default: false
        }
    }
}
