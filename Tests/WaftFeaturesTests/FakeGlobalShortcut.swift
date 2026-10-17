import WaftCore

final class FakeGlobalShortcut: GlobalShortcut {
    let title = "⌃⌥M"
    var registers = true

    private var action: (@MainActor () -> Void)?

    func register(_ action: @escaping @MainActor () -> Void) -> Bool {
        self.action = action

        return registers
    }

    func fire() {
        action?()
    }
}
