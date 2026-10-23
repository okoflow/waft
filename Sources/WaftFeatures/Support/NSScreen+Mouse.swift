import AppKit

extension NSScreen {
    static var underMouse: NSScreen? {
        let mouse = NSEvent.mouseLocation
        guard let screen = screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) else { return main }

        return screen
    }
}
