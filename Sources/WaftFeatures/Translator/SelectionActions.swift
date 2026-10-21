import Foundation
import WaftCore

final class SelectionActions {
    enum Action {
        case translate
        case fix
    }

    private static let releaseTimeout = Duration.seconds(5)
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
    }

    private static func workingLabel(for action: Action, into language: Language) -> String {
        switch action {
        case .translate: String(localized: "Translating into \(language.inlineName)…")
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

        guard let selection = target.element?.selectedText, !selection.isBlank else {
            hud.show(HUDMessage(kind: .information, title: String(localized: "Select the text first, then press the shortcut.")))

            return
        }

        task = Task { [weak self] in
            await self?.rework(selection, by: action, in: target)

            self?.task = nil
        }
    }

    private func rework(_ selection: String, by action: Action, in target: FocusTarget) async {
        let detected = detector.language(of: selection)

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

        hud.setWorking(Self.workingLabel(for: action, into: into))

        defer { hud.setWorking(nil) }

        do throws(RewriteError) {
            let reworked = try await processor.rework(
                selection,
                in: language,
                as: textTask,
                setup: setup,
            )

            let keys = Self.shortcutKeys
            let keyboardState = keyboardState

            await Poll.until(timeout: Self.releaseTimeout) { !keys.contains(where: keyboardState.isHeld) }

            await deliver(reworked, into: target)
        } catch {
            let reason = RewriteFallback(error).reason(for: setup.provider).sentenceCased()

            hud.show(HUDMessage(kind: .warning, title: Self.failureTitle(of: action), detail: reason))
        }
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
