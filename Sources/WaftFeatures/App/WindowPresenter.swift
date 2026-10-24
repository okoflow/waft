import AppKit
import SwiftUI

final class WindowPresenter: NSObject, NSWindowDelegate {
    private static let settingsSize = CGSize(width: 820, height: 660)
    private static let settingsMinimumSize = CGSize(width: 760, height: 520)
    private static let transcriptionSize = CGSize(width: 600, height: 580)
    private static let translatorSize = CGSize(width: 900, height: 460)

    var onOnboardingClose: () -> Void = {}
    var onSettingsClose: () -> Void = {}
    var onTranscriptionClose: () -> Void = {}
    var onTranslatorClose: () -> Void = {}
    var isShowingUpdate: () -> Bool = { false }
    var dictationTakesEscape: (TimeInterval) -> Bool = { _ in false }

    private let settingsState = SettingsWindowState()
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var transcriptionWindow: NSWindow?
    private var translatorPanel: TranslatorPanel?
    private var clickMonitor: Any?

    private var appWindows: [NSWindow] {
        [settingsWindow, onboardingWindow, transcriptionWindow].compactMap(\.self)
    }

    func windowWillClose(_ notification: Notification) {
        guard let closing = notification.object as? NSWindow else { return }

        if closing == onboardingWindow {
            onOnboardingClose()
        }

        if closing == settingsWindow {
            settingsState.closeEditor()
            onSettingsClose()
        }

        if closing == transcriptionWindow {
            onTranscriptionClose()
        }

        if closing == translatorPanel {
            onTranslatorClose()
        }

        updateActivationPolicy(closing: closing)
    }

    func showSettings(_ pane: SettingsPane?, for model: AppModel) {
        if let pane {
            settingsState.selection = pane
        }

        show(\.settingsWindow, for: model, make: makeSettingsWindow)
    }

    func showOnboarding(for model: AppModel) {
        show(\.onboardingWindow, for: model, make: makeOnboardingWindow)
    }

    func showTranscription(for model: AppModel) {
        show(\.transcriptionWindow, for: model, make: makeTranscriptionWindow)
    }

    func showTranslator(for model: AppModel) {
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

        return isShowingUpdate()
    }

    private func show(
        _ keyPath: ReferenceWritableKeyPath<WindowPresenter, NSWindow?>,
        for model: AppModel,
        make: (AppModel) -> NSWindow,
    ) {
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

    private func releaseFocus(for event: NSEvent) {
        guard let window = event.window,
              [settingsWindow, onboardingWindow].contains(window),
              window.clickLeavesEditedText(at: event.locationInWindow) else { return }

        window.makeFirstResponder(nil)
    }

    private func makeSettingsWindow(model: AppModel) -> NSWindow {
        let window = makeWindow(
            SettingsWindowView(model: model, state: settingsState),
            size: Self.settingsSize,
            minimumSize: Self.settingsMinimumSize,
            hasToolbar: true,
        )

        followSelectedPaneTitle(of: window)

        return window
    }

    private func makeTranscriptionWindow(model: AppModel) -> NSWindow {
        let view = TranscriptionView(model: model.transcription) { [weak model] in
            model?.showSettings(.pro)
        }

        return makeWindow(
            view,
            size: Self.transcriptionSize,
            minimumSize: TranscriptionView.minimumSize,
            title: String(localized: "Transcribe File"),
        )
    }

    private func makeTranslatorPanel(model: AppModel) -> TranslatorPanel {
        let view = TranslatorView(model: model.translator) { [weak self, weak model] in
            self?.translatorPanel?.close()
            model?.showSettings(.pro)
        }

        let panel = TranslatorPanel(content: hostingController(for: view)) { [weak self] event in
            guard let self else { return false }

            return dictationTakesEscape(event.timestamp)
        }

        panel.title = String(localized: "Translator")
        panel.setContentSize(Self.translatorSize)
        panel.contentMinSize = TranslatorView.minimumSize

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
}
