import Observation
import os
import WaftCore

@Observable
final class TranslatorShortcuts {
    private(set) var translatorTitle: String?
    private(set) var translateSelectionTitle: String?
    private(set) var fixSelectionTitle: String?

    @ObservationIgnored var onOpenTranslator: (() -> Void)?

    private let shortcuts: GlobalShortcuts
    private let selectionActions: SelectionActions

    init(shortcuts: GlobalShortcuts, selectionActions: SelectionActions) {
        self.shortcuts = shortcuts
        self.selectionActions = selectionActions
    }

    func start() {
        translatorTitle = register(shortcuts.translator) { [weak self] in self?.onOpenTranslator?() }
        translateSelectionTitle = register(shortcuts.translateSelection) { [weak self] in self?.selectionActions.run(.translate) }
        fixSelectionTitle = register(shortcuts.fixSelection) { [weak self] in self?.selectionActions.run(.fix) }
    }

    private func register(_ shortcut: any GlobalShortcut, action: @escaping @MainActor () -> Void) -> String? {
        guard shortcut.register(action) else {
            Logger.translator.error("Couldn't register the \(shortcut.title, privacy: .public) shortcut")

            return nil
        }

        return shortcut.title
    }
}
