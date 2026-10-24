import WaftCore
@testable import WaftFeatures

extension GlobalShortcutController {
    static func fake(
        _ shortcuts: [ShortcutAction: FakeGlobalShortcut] = [:],
        settings: SettingsModel = .inMemory(),
    ) -> GlobalShortcutController {
        let controller = GlobalShortcutController(shortcuts: .fake(shortcuts), settings: settings)

        settings.onShortcutsChange = { [weak controller] in controller?.settingsDidChange() }

        return controller
    }
}
