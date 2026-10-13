import AppKit
import SwiftUI

final class HUDPanel: NSPanel, HUDWindow {
    static let shadowRoom: CGFloat = 18

    private static let canvasSize = CGSize(width: 720, height: 220)
    private static let bottomInset: CGFloat = 36

    private static var screenUnderMouse: NSScreen? {
        let mouse = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) else { return NSScreen.main }

        return screen
    }

    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }

    init(rootView: some View) {
        super.init(
            contentRect: NSRect(origin: .zero, size: Self.canvasSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false,
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .statusBar
        ignoresMouseEvents = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        contentView = NSHostingView(rootView: rootView)
    }

    func showOnActiveScreen() {
        if let area = Self.screenUnderMouse?.visibleFrame {
            setFrameOrigin(NSPoint(x: area.midX - frame.width / 2, y: area.minY + Self.bottomInset - Self.shadowRoom))
        }

        orderFrontRegardless()
    }
}
