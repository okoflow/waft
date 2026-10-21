package import AppKit
import SwiftUI

package final class WindowPresenter: NSObject, NSWindowDelegate {
    weak var model: AppModel?

    private let settingsState = SettingsWindowState()
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var transcriptionWindow: NSWindow?
    private var translatorWindow: NSWindow?
    private var clickMonitor: Any?

    private var openWindows: [NSWindow] {
        [settingsWindow, onboardingWindow, transcriptionWindow, translatorWindow].compactMap(\.self)
    }

    private var isShowingUpdate: Bool {
        guard let model else { return false }

        return model.updates.isShowingUpdate
    }

    package func showSettings(_ pane: SettingsPane? = nil) {
        if let pane {
            settingsState.selection = pane
        }

        show(\.settingsWindow, make: makeSettingsWindow)
    }

    package func windowWillClose(_ notification: Notification) {
        guard let closing = notification.object as? NSWindow else { return }

        if closing == onboardingWindow {
            model?.onboarding.reset()
        }

        if closing == settingsWindow {
            settingsState.closeEditor()
            model?.keyRecorder.stop()
            model?.shortcutRecorder.stop()
        }

        if closing == transcriptionWindow {
            model?.transcription.cancel()
        }

        if closing == translatorWindow {
            model?.translator.stop()
        }

        updateActivationPolicy(closing: closing)
    }

    func showOnboarding() {
        show(\.onboardingWindow, make: makeOnboardingWindow)
    }

    func showTranscription() {
        show(\.transcriptionWindow, make: makeTranscriptionWindow)
    }

    func showTranslator() {
        model?.translator.resume()
        show(\.translatorWindow, make: makeTranslatorWindow)
    }

    func closeOnboarding() {
        onboardingWindow?.close()
    }

    func updateActivationPolicy(closing: NSWindow? = nil) {
        let hasVisibleWindow = openWindows.contains { $0 != closing && $0.isVisible }
        let needsDockIcon = hasVisibleWindow || isShowingUpdate

        NSApp.setActivationPolicy(needsDockIcon ? .regular : .accessory)
    }

    private func show(_ keyPath: ReferenceWritableKeyPath<WindowPresenter, NSWindow?>, make: (AppModel) -> NSWindow) {
        guard let model else { return }

        if self[keyPath: keyPath] == nil {
            self[keyPath: keyPath] = make(model)
        }

        guard let window = self[keyPath: keyPath] else { return }

        releaseFocusOnOutsideClicks()
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    private func releaseFocusOnOutsideClicks() {
        guard clickMonitor == nil else { return }

        clickMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            self?.releaseFocus(for: event)

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
        let window = makeWindow(
            SettingsWindowView(model: model, state: settingsState),
            size: Metrics.settingsSize,
            minimumSize: Metrics.settingsMinimumSize,
            hasToolbar: true,
        )

        followSelectedPaneTitle(of: window)

        return window
    }

    private func makeTranscriptionWindow(model: AppModel) -> NSWindow {
        let view = TranscriptionView(model: model.transcription) { [weak self] in
            self?.showSettings(.pro)
        }

        return makeWindow(
            view,
            size: Metrics.transcriptionSize,
            minimumSize: Metrics.transcriptionMinimumSize,
            title: String(localized: "Transcribe File"),
        )
    }

    private func makeTranslatorWindow(model: AppModel) -> NSWindow {
        let view = TranslatorView(model: model.translator) { [weak self] in
            self?.showSettings(.pro)
        }
        let window = makeWindow(
            view,
            size: Metrics.translatorSize,
            minimumSize: Metrics.translatorMinimumSize,
            title: String(localized: "Translator"),
        )
        window.titleVisibility = .visible

        return window
    }

    private func makeOnboardingWindow(model: AppModel) -> NSWindow {
        let content = NSHostingController(rootView: OnboardingView(model: model).tint(Palette.accent))
        content.sizingOptions = .preferredContentSize
        content.safeAreaRegions = []

        let window = NSWindow(contentViewController: content)
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.isMovableByWindowBackground = true

        style(window)

        return window
    }

    private func makeWindow(
        _ view: some View,
        size: NSSize,
        minimumSize: NSSize,
        title: String? = nil,
        hasToolbar: Bool = false,
    ) -> NSWindow {
        let content = NSHostingController(rootView: view.tint(Palette.accent))
        content.sizingOptions = []

        let window = NSWindow(contentViewController: content)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]

        if let title {
            window.title = title
        }

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
