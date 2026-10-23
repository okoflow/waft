import AppKit
import SwiftUI

final class HUDPanel: NSPanel, HUDWindow {
    private static let canvasSize = CGSize(width: 640, height: 280)
    private static let trackingInterval: TimeInterval = 1.0 / 30
    private static let menuBarGap: CGFloat = 8

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

    private static func quartzFrame(of screen: NSScreen) -> CGRect {
        guard let primary = NSScreen.screens.first else { return screen.frame }

        return CGRect(
            x: screen.frame.minX,
            y: primary.frame.height - screen.frame.maxY,
            width: screen.frame.width,
            height: screen.frame.height,
        )
    }

    private static func restArea(on screen: CGRect, notch: CGSize?) -> CGRect {
        var size = CGSize(width: 2 * HUDLayout.wing, height: NSStatusBar.system.thickness)

        if let notch {
            size = notch
        }

        return CGRect(x: screen.midX - size.width / 2, y: screen.minY, width: size.width, height: size.height)
    }

    private static func menuBarHeight(of screen: NSScreen) -> CGFloat {
        max(screen.safeAreaInsets.top, screen.frame.maxY - screen.visibleFrame.maxY, NSStatusBar.system.thickness)
    }

    private static func level(above coveringLevel: Int) -> NSWindow.Level {
        NSWindow.Level(rawValue: max(NSWindow.Level.statusBar.rawValue, coveringLevel + 1))
    }

    func showOnActiveScreen() {
        guard let screen = NSScreen.underMouse else { return }

        let notch = Self.notch(of: screen)
        let quartzFrame = Self.quartzFrame(of: screen)

        let coveringLevel = ForeignWindow.coveringLevel(
            of: Self.restArea(on: quartzFrame, notch: notch),
            on: quartzFrame,
            among: ForeignWindow.onScreen(),
        )

        var top = screen.frame.maxY

        if let coveringLevel {
            level = Self.level(above: coveringLevel)
            layout.placeBelowMenuBar()
            top -= Self.menuBarHeight(of: screen) + Self.menuBarGap
        } else {
            level = .statusBar
            layout.place(around: notch)
        }

        setFrameOrigin(NSPoint(x: screen.frame.midX - frame.width / 2, y: top - frame.height))
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
