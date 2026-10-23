import Foundation
import WaftCore

final class SelectionActions {
    enum Action {
        case translate
        case fix
    }

    private static let shortcutKeys = [54, 55, 56, 58, 59, 60, 61, 62].compactMap { PushToTalkKey(keyCode: $0) }

    private var task: Task<Void, Never>?

    private let processor: TranscriptProcessor
    private let detector: any LanguageDetector
    private let focusTracker: any FocusTracker
    private let keyboardState: any KeyboardState
    private let inserter: any TextInserter
    private let clipboard: any Clipboard
    private let settings: SettingsModel
    private let pro: ProModel
    private let hud: HUDController
    private let releaseTimeout: Duration

    init(
        rewriters: Rewriters,
        detector: any LanguageDetector,
        focusTracker: any FocusTracker,
        keyboardState: any KeyboardState,
        inserter: any TextInserter,
        clipboard: any Clipboard,
        settings: SettingsModel,
        pro: ProModel,
        hud: HUDController,
        releaseTimeout: Duration = .seconds(5),
    ) {
        processor = TranscriptProcessor(rewriters: rewriters)
        self.detector = detector
        self.focusTracker = focusTracker
        self.keyboardState = keyboardState
        self.inserter = inserter
        self.clipboard = clipboard
        self.settings = settings
        self.pro = pro
        self.hud = hud
        self.releaseTimeout = releaseTimeout
    }

    private static func workingLabel(for action: Action) -> String {
        switch action {
        case .translate: String(localized: "Translating…")
        case .fix: String(localized: "Fixing the text…")
        }
    }

    private static func failureTitle(of action: Action) -> String {
        switch action {
        case .translate: String(localized: "Couldn't translate the text")
        case .fix: String(localized: "Couldn't fix the text")
        }
    }

    func run(_ action: Action) {
        guard task == nil else { return }
        guard pro.isUnlocked else {
            hud.show(HUDMessage(kind: .information, title: String(localized: "Translating and fixing text is part of Waft+.")))

            return
        }

        let target = focusTracker.currentFocus()

        task = Task { [weak self] in
            await self?.reworkSelection(by: action, in: target)

            self?.task = nil
        }
    }

    private func reworkSelection(by action: Action, in target: FocusTarget) async {
        let selection = await selectedText(in: target)
        guard let selection, !selection.isBlank else {
            hud.show(HUDMessage(kind: .information, title: String(localized: "Select the text first, then press the shortcut.")))

            return
        }

        await rework(selection, by: action, in: target)
    }

    private func selectedText(in target: FocusTarget) async -> String? {
        guard let selection = target.element?.selectedText else { return await copiedSelection(in: target) }

        return selection
    }

    private func copiedSelection(in target: FocusTarget) async -> String? {
        guard !showsOnlyCaret(target), await waitForShortcutRelease() else { return nil }

        return await inserter.copySelection(from: target)
    }

    private func showsOnlyCaret(_ target: FocusTarget) -> Bool {
        guard let element = target.element else { return false }

        return element.hasEmptySelection
    }

    private func rework(_ selection: String, by action: Action, in target: FocusTarget) async {
        let detected = detector.language(of: selection, expecting: settings.settings.expectedTranslatorLanguages)

        let into = settings.settings.translator.target(forSource: detected)

        let language =
            if let detected {
                detected
            } else {
                into
            }

        let textTask: TextTask =
            switch action {
            case .translate: .translate(from: nil, into: into)
            case .fix: .fix
            }

        let setup = settings.settings.translatorSetup(for: textTask.kind)

        hud.setWorking(Self.workingLabel(for: action))

        defer { hud.setWorking(nil) }

        do throws(RewriteError) {
            let reworked = try await processor.rework(
                selection,
                in: language,
                as: textTask,
                setup: setup,
            )

            await waitForShortcutRelease()

            await deliver(reworked, into: target)
        } catch {
            let reason = RewriteFallback(error).reason(for: setup.provider).sentenceCased()

            hud.show(HUDMessage(kind: .warning, title: Self.failureTitle(of: action), detail: reason))
        }
    }

    @discardableResult
    private func waitForShortcutRelease() async -> Bool {
        let keys = Self.shortcutKeys
        let keyboardState = keyboardState

        return await Poll.until(timeout: releaseTimeout) { !keys.contains(where: keyboardState.isHeld) }
    }

    private func deliver(_ text: String, into target: FocusTarget) async {
        switch await inserter.insert(text, into: target, releasing: settings.settings.pushToTalkKey) {
        case .pasted:
            hud.show(HUDMessage(kind: .pasted, title: text))

        case .skipped(.secureField):
            hud.show(HUDMessage(kind: .warning, title: String(localized: "Not pasted into a password field")))

        case .skipped:
            clipboard.copy(text)
            hud.show(.copied(text))
        }
    }
}
