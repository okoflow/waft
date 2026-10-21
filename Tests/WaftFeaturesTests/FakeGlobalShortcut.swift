import WaftCore

final class FakeGlobalShortcut: GlobalShortcut {
    let title: String
    var registers: Bool

    private var action: (@MainActor () -> Void)?

    init(title: String = "⌃⌥M", registers: Bool = true) {
        self.title = title
        self.registers = registers
    }

    func register(_ action: @escaping @MainActor () -> Void) -> Bool {
        self.action = action

        return registers
    }

    func fire() {
        action?()
    }
}
