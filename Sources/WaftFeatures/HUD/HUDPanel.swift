import AppKit
import SwiftUI

final class HUDPanel: NSPanel, HUDWindow {
    private static let canvasSize = CGSize(width: 640, height: 280)
    private static let trackingInterval: TimeInterval = 1.0 / 30

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

    private let hud: HUDController
    private let layout = HUDLayout()
    private var trackingTimer: Timer?

    init(hud: HUDController) {
        self.hud = hud

        super.init(
            contentRect: NSRect(origin: .zero, size: Self.canvasSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false,
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        animationBehavior = .none
        level = .statusBar
        ignoresMouseEvents = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        contentView = NSHostingView(rootView: HUDView(hud: hud, layout: layout))
    }

    override func orderOut(_ sender: Any?) {
        trackingTimer?.invalidate()
        trackingTimer = nil
        ignoresMouseEvents = true

        super.orderOut(sender)
    }

    private static func notch(of screen: NSScreen) -> CGSize? {
        guard screen.safeAreaInsets.top > 0,
              let left = screen.auxiliaryTopLeftArea,
              let right = screen.auxiliaryTopRightArea else {
            return nil
        }

        return CGSize(width: right.minX - left.maxX, height: screen.safeAreaInsets.top)
    }

    func showOnActiveScreen() {
        guard let screen = Self.screenUnderMouse else { return }

        layout.place(around: Self.notch(of: screen))
        setFrameOrigin(NSPoint(x: screen.frame.midX - frame.width / 2, y: screen.frame.maxY - frame.height))
        orderFrontRegardless()
        startTracking()
    }

    private func startTracking() {
        guard trackingTimer == nil else { return }

        trackingTimer = .scheduledInCommonModes(every: Self.trackingInterval, repeats: true) { [weak self] in
            self?.updateMouseEvents()
        }
    }

    private func updateMouseEvents() {
        let mouse = NSEvent.mouseLocation

        guard hud.canCopyMessage, let island = layout.islandFrame else {
            ignoresMouseEvents = true
            hud.pointerMoved(to: mouse, isOver: false)

            return
        }

        let onScreen = NSRect(
            x: frame.minX + island.minX,
            y: frame.maxY - island.maxY,
            width: island.width,
            height: island.height,
        )

        let isOver = onScreen.contains(mouse)

        ignoresMouseEvents = !isOver
        hud.pointerMoved(to: mouse, isOver: isOver)
    }
}
