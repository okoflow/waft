package import AppKit
import SwiftUI

package final class WindowPresenter: NSObject, NSWindowDelegate {
    weak var model: AppModel?

    private let settingsState = SettingsWindowState()
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var transcriptionWindow: NSWindow?
    private var translatorPanel: TranslatorPanel?
    private var clickMonitor: Any?

    private var appWindows: [NSWindow] {
        [settingsWindow, onboardingWindow, transcriptionWindow].compactMap(\.self)
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

        if closing == translatorPanel {
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
        guard let model else { return }

        model.translator.resume()
        reusableWindow(at: \.translatorPanel) { makeTranslatorPanel(model: model) }.present()
    }

    func closeOnboarding() {
        onboardingWindow?.close()
    }

    func updateActivationPolicy(closing: NSWindow? = nil) {
        NSApp.setActivationPolicy(needsDockIcon(closing: closing) ? .regular : .accessory)
    }

    private func needsDockIcon(closing: NSWindow?) -> Bool {
        let otherWindows = appWindows.filter { $0 != closing }
        guard !otherWindows.contains(where: \.isOpen) else { return true }

        return isShowingUpdate
    }

    private func show(_ keyPath: ReferenceWritableKeyPath<WindowPresenter, NSWindow?>, make: (AppModel) -> NSWindow) {
        guard let model else { return }

        let window = reusableWindow(at: keyPath) { make(model) }

        model.permissions.refresh()
        releaseFocusOnOutsideClicks()
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    private func reusableWindow<Window: NSWindow>(
        at keyPath: ReferenceWritableKeyPath<WindowPresenter, Window?>,
        make: () -> Window,
    ) -> Window {
        if let window = self[keyPath: keyPath] {
            return window
        }

        let window = make()

        self[keyPath: keyPath] = window

        return window
    }

    private func releaseFocusOnOutsideClicks() {
        guard clickMonitor == nil else { return }

        clickMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            self?.releaseFocus(for: event)

            return event
        }
    }

    private func dictationTakes(_ escape: NSEvent) -> Bool {
        guard let model else { return false }

        return model.dictationTakesEscape(pressedAt: escape.timestamp)
    }

    private func releaseFocus(for event: NSEvent) {
        guard let window = event.window,
              [settingsWindow, onboardingWindow].contains(window),
              window.clickLeavesEditedText(at: event.locationInWindow) else { return }

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

    private func makeTranslatorPanel(model: AppModel) -> TranslatorPanel {
        let view = TranslatorView(model: model.translator) { [weak self] in
            self?.translatorPanel?.close()
            self?.showSettings(.pro)
        }

        let panel = TranslatorPanel(content: hostingController(for: view)) { [weak self] event in
            guard let self else { return false }

            return dictationTakes(event)
        }

        panel.title = String(localized: "Translator")
        panel.setContentSize(Metrics.translatorSize)
        panel.contentMinSize = Metrics.translatorMinimumSize

        style(panel)

        panel.titleVisibility = .visible

        return panel
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
        let window = NSWindow(contentViewController: hostingController(for: view))
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

    private func hostingController(for view: some View) -> NSViewController {
        let content = NSHostingController(rootView: view.tint(Palette.accent))
        content.sizingOptions = []

        return content
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

extension NSWindow {
    fileprivate var isOpen: Bool {
        [isVisible, isMiniaturized].contains(true)
    }

    fileprivate func clickLeavesEditedText(at location: NSPoint) -> Bool {
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
