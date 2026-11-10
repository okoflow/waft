package import WaftCore

package struct GlobalShortcuts {
    let layout: any KeyboardLayout

    private let modeCycle: any GlobalShortcut
    private let translator: any GlobalShortcut
    private let translateSelection: any GlobalShortcut
    private let fixSelection: any GlobalShortcut

    package init(layout: any KeyboardLayout, _ shortcut: (ShortcutAction) -> any GlobalShortcut) {
        self.layout = layout
        modeCycle = shortcut(.modeCycle)
        translator = shortcut(.translator)
        translateSelection = shortcut(.translateSelection)
        fixSelection = shortcut(.fixSelection)
    }

    subscript(_ action: ShortcutAction) -> any GlobalShortcut {
        switch action {
        case .modeCycle: modeCycle
        case .translator: translator
        case .translateSelection: translateSelection
        case .fixSelection: fixSelection
        }
    }
}
