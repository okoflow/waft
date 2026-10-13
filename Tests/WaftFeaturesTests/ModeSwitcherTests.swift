import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct ModeSwitcherTests {
    private let shortcut = FakeGlobalShortcut()
    private let settings = SettingsModel.inMemory()
    private let hud = HUDController.offscreen()

    @Test(arguments: [(true, "⌃⌥M"), (false, nil)] as [(Bool, String?)])
    func `shows the shortcut title only once the shortcut registers`(registers: Bool, title: String?) {
        shortcut.registers = registers
        let switcher = ModeSwitcher(shortcut: shortcut, settings: settings, hud: hud, pro: .unlicensed())
        switcher.start()

        #expect(switcher.shortcutTitle == title)
    }

    @Test
    func `switches to the next mode and announces it when the shortcut fires`() {
        let switcher = ModeSwitcher(shortcut: shortcut, settings: settings, hud: hud, pro: .unlicensed())
        switcher.start()
        shortcut.fire()

        #expect(settings.settings.mode == .clean)
        #expect(hud.content == .message(HUDMessage(kind: .info, title: "Mode: Clean")))
    }

    @Test(.enabled(if: !ProAccess.isFreeDuringBeta))
    func `skips the AI modes without Pro`() {
        let switcher = ModeSwitcher(
            shortcut: shortcut,
            settings: settings,
            hud: hud,
            pro: .unlicensed(trialStarted: .distantPast),
        )
        switcher.start()
        shortcut.fire()

        #expect(settings.settings.mode == .raw)
    }
}

private final class FakeGlobalShortcut: GlobalShortcut {
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
