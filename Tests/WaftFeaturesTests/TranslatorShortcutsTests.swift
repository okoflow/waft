import Testing
import WaftCore
@testable import WaftFeatures

struct TranslatorShortcutsTests {
    @Test
    func `opens the translator from its shortcut and names every shortcut`() {
        let window = FakeGlobalShortcut(title: "⌃⌥T")
        let shortcuts = shortcuts(.fake(
            translator: window,
            translateSelection: FakeGlobalShortcut(title: "⌃⌥⇧T"),
            fixSelection: FakeGlobalShortcut(title: "⌃⌥F"),
        ))
        var opens = 0
        shortcuts.onOpenTranslator = { opens += 1 }
        shortcuts.start()

        window.fire()

        #expect(opens == 1)
        #expect(shortcuts.translatorTitle == "⌃⌥T")
        #expect(shortcuts.translateSelectionTitle == "⌃⌥⇧T")
        #expect(shortcuts.fixSelectionTitle == "⌃⌥F")
    }

    @Test
    func `names no shortcut that macOS refused`() {
        let shortcuts = shortcuts(.fake(fixSelection: FakeGlobalShortcut(title: "⌃⌥F", registers: false)))
        shortcuts.start()

        #expect(shortcuts.fixSelectionTitle == nil)
        #expect(shortcuts.translatorTitle != nil)
    }

    private func shortcuts(_ global: GlobalShortcuts) -> TranslatorShortcuts {
        let actions = SelectionActions(
            rewriters: .all(FakeTextRewriter()),
            detector: FakeLanguageDetector(),
            focusTracker: FakeFocusTracker(),
            keyboardState: FakeKeyboardState(holdsKeys: false),
            inserter: FakeTextInserter(),
            clipboard: FakeClipboard(),
            settings: SettingsModel.inMemory(),
            pro: .unlicensed(),
            hud: HUDController.offscreen(),
        )

        return TranslatorShortcuts(shortcuts: global, selectionActions: actions)
    }
}
