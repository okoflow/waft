import Testing
import WaftCore
@testable import WaftFeatures

struct GlobalShortcutControllerTests {
    private static let controlOptionK = KeyCombination(keyCode: 40, modifiers: [.control, .option])

    private let shortcut = FakeGlobalShortcut()
    private let settings = SettingsModel.inMemory()

    @Test
    func `registers the stored combination once an action has a handler`() {
        let controller = GlobalShortcutController.fake([.modeCycle: shortcut], settings: settings)
        var fires = 0
        controller.handle(.modeCycle) { fires += 1 }

        shortcut.fire()

        #expect(shortcut.registered == ShortcutAction.modeCycle.defaultCombination)
        #expect(fires == 1)
        #expect(controller.title(for: .modeCycle) == "⌃⌥M")
    }

    @Test
    func `registers the new combination when the setting changes`() {
        let controller = GlobalShortcutController.fake([.modeCycle: shortcut], settings: settings)
        controller.handle(.modeCycle) {}

        settings.settings.shortcuts[.modeCycle] = Self.controlOptionK
        settings.settings.playsSounds = false

        #expect(shortcut.registered == Self.controlOptionK)
        #expect(shortcut.registrations == [ShortcutAction.modeCycle.defaultCombination, Self.controlOptionK])
    }

    @Test
    func `unregisters a cleared shortcut and names none`() {
        let controller = GlobalShortcutController.fake([.translator: shortcut], settings: settings)
        controller.handle(.translator) {}

        settings.settings.shortcuts[.translator] = nil

        #expect(shortcut.registered == nil)
        #expect(controller.title(for: .translator) == nil)
        #expect(!controller.unavailable.contains(.translator))
    }

    @Test
    func `marks a shortcut that macOS refused as unavailable until another one registers`() {
        shortcut.registers = false
        let controller = GlobalShortcutController.fake([.fixSelection: shortcut], settings: settings)
        controller.handle(.fixSelection) {}

        #expect(controller.unavailable == [.fixSelection])
        #expect(controller.title(for: .fixSelection) == nil)

        shortcut.registers = true
        settings.settings.shortcuts[.fixSelection] = Self.controlOptionK

        #expect(controller.unavailable.isEmpty)
        #expect(controller.title(for: .fixSelection) == "⌃⌥K")
    }

    @Test
    func `releases every shortcut while suspended and registers them again on resume`() {
        let controller = GlobalShortcutController.fake([.translator: shortcut], settings: settings)
        controller.handle(.translator) {}

        controller.suspend()

        #expect(shortcut.registered == nil)

        controller.resume()

        #expect(shortcut.registered == ShortcutAction.translator.defaultCombination)
    }
}
