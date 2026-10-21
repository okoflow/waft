import WaftCore

final class FakeGlobalShortcut: GlobalShortcut {
    var registers: Bool
    private(set) var registered: KeyCombination?
    private(set) var registrations: [KeyCombination] = []

    private var action: (@MainActor () -> Void)?

    init(registers: Bool = true) {
        self.registers = registers
    }

    func register(_ combination: KeyCombination, action: @escaping @MainActor () -> Void) -> Bool {
        registrations.append(combination)

        guard registers else { return false }

        registered = combination
        self.action = action

        return true
    }

    func unregister() {
        registered = nil
        action = nil
    }

    func fire() {
        action?()
    }
}
