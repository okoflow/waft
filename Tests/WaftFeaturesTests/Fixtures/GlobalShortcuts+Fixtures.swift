import WaftCore
import WaftFeatures

extension GlobalShortcuts {
    static func fake(_ shortcuts: [ShortcutAction: FakeGlobalShortcut] = [:]) -> GlobalShortcuts {
        GlobalShortcuts(layout: FakeKeyboardLayout()) { action in
            shortcuts[action, default: FakeGlobalShortcut()]
        }
    }
}
