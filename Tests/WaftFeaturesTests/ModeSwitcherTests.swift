import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct ModeSwitcherTests {
    private let shortcut = FakeGlobalShortcut()
    private let settings = SettingsModel.inMemory()
    private let hud = HUDController.offscreen()

    private var shortcuts: GlobalShortcutController {
        .fake([.modeCycle: shortcut], settings: settings)
    }

    @Test
    func `registers the mode shortcut when it starts`() {
        let switcher = ModeSwitcher(shortcuts: shortcuts, settings: settings, hud: hud, pro: .unlicensed())
        switcher.start()

        #expect(shortcut.registered == ShortcutAction.modeCycle.defaultCombination)
    }

    @Test
    func `switches to the next mode and announces it when the shortcut fires`() {
        let switcher = ModeSwitcher(shortcuts: shortcuts, settings: settings, hud: hud, pro: .unlicensed())
        switcher.start()
        shortcut.fire()

        #expect(settings.settings.mode == .clean)
        #expect(hud.content == .message(HUDMessage(kind: .information, title: "Mode: Clean")))
    }

    @Test
    func `switches through the custom modes and announces them by name`() {
        settings.settings.customModes = [.emailReply]
        settings.settings.mode = .translate
        let switcher = ModeSwitcher(shortcuts: shortcuts, settings: settings, hud: hud, pro: .unlicensed())
        switcher.start()
        shortcut.fire()

        #expect(settings.settings.mode == .custom(CustomMode.emailReply.id))
        #expect(hud.content == .message(HUDMessage(kind: .information, title: "Mode: Email reply")))

        shortcut.fire()

        #expect(settings.settings.mode == .raw)
    }

    @Test(.enabled(if: !ProAccess.isFreeDuringBeta))
    func `skips the AI modes without Pro`() {
        let switcher = ModeSwitcher(
            shortcuts: shortcuts,
            settings: settings,
            hud: hud,
            pro: .unlicensed(trialStarted: .distantPast),
        )

        switcher.start()
        shortcut.fire()

        #expect(settings.settings.mode == .raw)
    }
}
