package import AppKit
import SwiftUI

@MainActor
package final class WindowPresenter: NSObject, NSWindowDelegate {
    weak var model: AppModel?

    private let settingsState = SettingsWindowState()
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var transcriptionWindow: NSWindow?
    private var clickMonitor: Any?

    private var openWindows: [NSWindow] {
        [settingsWindow, onboardingWindow, transcriptionWindow].compactMap(\.self)
    }

    private var isShowingUpdate: Bool {
        guard let model else { return false }

        return model.updates.isShowingUpdate
    }

    package func showSettings(_ pane: SettingsPane? = nil) {
        guard let model else { return }

        if let pane {
            settingsState.selection = pane
        }

        present(window(\.settingsWindow) { makeSettingsWindow(model: model) })
    }

    package func windowWillClose(_ notification: Notification) {
        guard let closing = notification.object as? NSWindow else { return }

        if closing == onboardingWindow {
            model?.onboarding.reset()
        }

        if closing == settingsWindow {
            settingsState.editedMode = nil
            model?.keyRecorder.stop()
        }

        if closing == transcriptionWindow {
            model?.transcription.cancel()
        }

        updateActivationPolicy(closing: closing)
    }

    func showOnboarding() {
        guard let model else { return }

        present(window(\.onboardingWindow) { makeOnboardingWindow(model: model) })
    }

    func showTranscription() {
        guard let model else { return }

        present(window(\.transcriptionWindow) { makeTranscriptionWindow(model: model) })
    }

    func closeOnboarding() {
        onboardingWindow?.close()
    }

    func updateActivationPolicy(closing: NSWindow? = nil) {
        let hasVisibleWindow = openWindows.contains { $0 != closing && $0.isVisible }
        let needsDockIcon = hasVisibleWindow || isShowingUpdate

        NSApp.setActivationPolicy(needsDockIcon ? .regular : .accessory)
    }

    private func window(_ keyPath: ReferenceWritableKeyPath<WindowPresenter, NSWindow?>, make: () -> NSWindow) -> NSWindow {
        if let existing = self[keyPath: keyPath] {
            return existing
        }

        let window = make()
        self[keyPath: keyPath] = window

        return window
    }

    private func present(_ window: NSWindow) {
        releaseFocusOnOutsideClicks()
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    private func releaseFocusOnOutsideClicks() {
        guard clickMonitor == nil else { return }

        clickMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            MainActor.assumeIsolated {
                self?.releaseFocus(for: event)
            }

            return event
        }
    }

    private func releaseFocus(for event: NSEvent) {
        guard let window = event.window, [settingsWindow, onboardingWindow].contains(window),
              window.firstResponder is NSText,
              let hit = window.contentView?.hitTest(event.locationInWindow), !hit.isTextInput
        else { return }

        window.makeFirstResponder(nil)
    }

    private func makeSettingsWindow(model: AppModel) -> NSWindow {
        let content = NSHostingController(rootView: SettingsWindowView(model: model, state: settingsState))
        content.sizingOptions = []

        let window = makeWindow(
            content,
            size: NSSize(width: 820, height: 660),
            minimumSize: NSSize(width: 760, height: 520),
            hasToolbar: true,
        )

        followSelectedPaneTitle(of: window)

        return window
    }

    private func makeTranscriptionWindow(model: AppModel) -> NSWindow {
        let view = TranscriptionView(model: model.transcription) { [weak self] in
            self?.showSettings(.pro)
        }
        let content = NSHostingController(rootView: view)
        content.sizingOptions = []

        let window = makeWindow(content, size: NSSize(width: 600, height: 580), minimumSize: Metrics.transcriptionMinimumSize)
        window.title = String(localized: "Transcribe File")

        return window
    }

    private func makeOnboardingWindow(model: AppModel) -> NSWindow {
        let content = NSHostingController(rootView: OnboardingView(model: model))
        content.sizingOptions = .preferredContentSize
        content.safeAreaRegions = []

        let window = NSWindow(contentViewController: content)
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.isMovableByWindowBackground = true

        style(window)

        return window
    }

    private func makeWindow(
        _ content: NSViewController,
        size: NSSize,
        minimumSize: NSSize,
        hasToolbar: Bool = false,
    ) -> NSWindow {
        let window = NSWindow(contentViewController: content)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]

        if hasToolbar {
            window.toolbar = NSToolbar()
            window.toolbarStyle = .unified
        }

        window.setContentSize(size)
        window.contentMinSize = minimumSize

        style(window)

        return window
    }

    private func style(_ window: NSWindow) {
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.titlebarSeparatorStyle = .none
        window.backgroundColor = Palette.windowColor
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
    }

    private func followSelectedPaneTitle(of window: NSWindow) {
        withObservationTracking {
            window.title = settingsState.selection.title
        } onChange: { [weak self, weak window] in
            Task { @MainActor in
                guard let self, let window else { return }

                self.followSelectedPaneTitle(of: window)
            }
        }
    }
}

extension NSView {
    fileprivate var isTextInput: Bool {
        sequence(first: self, next: \.superview).contains { view in
            view is NSTextView || view is NSTextField || (view as? NSScrollView)?.documentView is NSTextView
        }
    }
}
