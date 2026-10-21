import Foundation
import WaftCore

final class ModeSwitcher {
    private let shortcuts: GlobalShortcutController
    private let settings: SettingsModel
    private let hud: HUDController
    private let pro: ProModel

    init(shortcuts: GlobalShortcutController, settings: SettingsModel, hud: HUDController, pro: ProModel) {
        self.shortcuts = shortcuts
        self.settings = settings
        self.hud = hud
        self.pro = pro
    }

    func start() {
        shortcuts.handle(.modeCycle) { [weak self] in
            self?.switchToNextMode()
        }
    }

    private func switchToNextMode() {
        settings.settings.mode = settings.settings.mode(after: settings.settings.mode, includingAI: pro.isUnlocked)

        let title = settings.settings.title(of: settings.settings.mode)

        hud.show(HUDMessage(kind: .information, title: String(localized: "Mode: \(title)")))
    }
}
