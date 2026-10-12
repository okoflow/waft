import AppKit

struct Confirmation {
    let message: String
    let detail: String
    let action: String

    func ask() -> Bool {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = detail
        alert.addButton(withTitle: action)
        alert.addButton(withTitle: String(localized: "Cancel"))
        alert.buttons.first?.hasDestructiveAction = true

        return alert.runModal() == .alertFirstButtonReturn
    }
}
