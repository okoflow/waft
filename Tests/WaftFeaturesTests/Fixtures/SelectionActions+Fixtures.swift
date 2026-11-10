import WaftCore
@testable import WaftFeatures

extension SelectionActions {
    static func acting(
        settings: SettingsModel,
        rewriter: FakeTextRewriter = FakeTextRewriter(),
        detector: FakeLanguageDetector = FakeLanguageDetector(),
        focusTracker: FakeFocusTracker = FakeFocusTracker(),
        keyboardState: FakeKeyboardState = FakeKeyboardState(holdsKeys: false),
        inserter: FakeTextInserter = FakeTextInserter(),
        clipboard: FakeClipboard = FakeClipboard(),
        pro: ProModel = .unlicensed(),
        hud: HUDController = .offscreen(),
    ) -> SelectionActions {
        SelectionActions(
            rewriters: .all(rewriter),
            detector: detector,
            focusTracker: focusTracker,
            keyboardState: keyboardState,
            inserter: inserter,
            clipboard: clipboard,
            settings: settings,
            pro: pro,
            hud: hud,
            releaseTimeout: .zero,
        )
    }
}
