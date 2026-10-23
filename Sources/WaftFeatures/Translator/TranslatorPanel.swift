import AppKit

final class TranslatorPanel: NSPanel {
    private static let heightAboveCenter: CGFloat = 0.6

    private static let leavingNotifications = [
        NSWorkspace.didActivateApplicationNotification,
        NSWorkspace.activeSpaceDidChangeNotification,
    ]

    private let dictationTakes: (NSEvent) -> Bool
    private var escapeMonitor: Any?
    private var clickMonitor: Any?
    private var leavingObservers: [any NSObjectProtocol] = []

    init(content: NSViewController, dictationTakes: @escaping (NSEvent) -> Bool) {
        self.dictationTakes = dictationTakes

        super.init(
            contentRect: .zero,
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false,
        )

        contentViewController = content
        isFloatingPanel = true
        hidesOnDeactivate = false
        animationBehavior = .utilityWindow
        collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
    }

    override func close() {
        stopWatching()
        guard isVisible else { return }

        super.close()
    }

    func present() {
        if !isVisible, let screen = NSScreen.underMouse {
            place(on: screen)
        }

        makeKeyAndOrderFront(nil)
        closeOnLeaving()
    }

    private func place(on screen: NSScreen) {
        let area = screen.visibleFrame

        let size = NSSize(width: min(frame.width, area.width), height: min(frame.height, area.height))

        let origin = NSPoint(
            x: area.midX - size.width / 2,
            y: area.minY + (area.height - size.height) * Self.heightAboveCenter,
        )

        setFrame(NSRect(origin: origin, size: size), display: false)
    }

    private func closeOnLeaving() {
        guard escapeMonitor == nil else { return }

        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, closes(on: event) else { return event }

            performClose(nil)

            return nil
        }

        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.close()
        }

        leavingObservers = Self.leavingNotifications.map { name in
            NSWorkspace.shared.notificationCenter
                .addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
                    let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
                    guard app != NSRunningApplication.current else { return }

                    MainActor.assumeIsolated { self?.close() }
                }
        }
    }

    private func stopWatching() {
        for monitor in [escapeMonitor, clickMonitor].compactMap(\.self) {
            NSEvent.removeMonitor(monitor)
        }

        for observer in leavingObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }

        escapeMonitor = nil
        clickMonitor = nil
        leavingObservers = []
    }

    private func closes(on event: NSEvent) -> Bool {
        guard event.isPlainEscape, event.window == self, !dictationTakes(event) else { return false }
        guard let editor = firstResponder as? NSTextView else { return true }

        return !editor.hasMarkedText()
    }
}
