import WaftCore

final class TranslatorShortcuts {
    var onOpenTranslator: (() -> Void)?

    private let shortcuts: GlobalShortcutController
    private let selectionActions: SelectionActions

    var onUsage: ((UsageEvent) -> Void)? {
        get { selectionActions.onUsage }
        set { selectionActions.onUsage = newValue }
    }

    init(shortcuts: GlobalShortcutController, selectionActions: SelectionActions) {
        self.shortcuts = shortcuts
        self.selectionActions = selectionActions
    }

    func start() {
        shortcuts.handle(.translator) { [weak self] in self?.onOpenTranslator?() }
        shortcuts.handle(.translateSelection) { [weak self] in self?.selectionActions.run(.translate) }
        shortcuts.handle(.fixSelection) { [weak self] in self?.selectionActions.run(.fix) }
    }
}
