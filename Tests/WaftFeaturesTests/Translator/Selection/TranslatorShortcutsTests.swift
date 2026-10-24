import Testing
import WaftCore
@testable import WaftFeatures

struct TranslatorShortcutsTests {
    @Test
    func `registers the three shortcuts and opens the translator from its own`() {
        let window = FakeGlobalShortcut()
        let translate = FakeGlobalShortcut()
        let fix = FakeGlobalShortcut()
        let settings = SettingsModel.inMemory()
        let controller = GlobalShortcutController.fake(
            [.translator: window, .translateSelection: translate, .fixSelection: fix],
            settings: settings,
        )
        let shortcuts = TranslatorShortcuts(shortcuts: controller, selectionActions: selectionActions(settings: settings))
        var opens = 0
        shortcuts.onOpenTranslator = { opens += 1 }
        shortcuts.start()

        window.fire()

        #expect(opens == 1)
        #expect(window.registered == ShortcutAction.translator.defaultCombination)
        #expect(translate.registered == ShortcutAction.translateSelection.defaultCombination)
        #expect(fix.registered == ShortcutAction.fixSelection.defaultCombination)
    }

    private func selectionActions(settings: SettingsModel) -> SelectionActions {
        SelectionActions(
            rewriters: .all(FakeTextRewriter()),
            detector: FakeLanguageDetector(),
            focusTracker: FakeFocusTracker(),
            keyboardState: FakeKeyboardState(holdsKeys: false),
            inserter: FakeTextInserter(),
            clipboard: FakeClipboard(),
            settings: settings,
            pro: .unlicensed(),
            hud: HUDController.offscreen(),
        )
    }
}
