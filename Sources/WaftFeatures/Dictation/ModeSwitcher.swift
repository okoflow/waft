import Foundation
import Observation
import os
import WaftCore

@Observable
final class ModeSwitcher {
    private(set) var shortcutTitle: String?

    private let shortcut: any GlobalShortcut
    private let settings: SettingsModel
    private let hud: HUDController
    private let pro: ProModel

    init(shortcut: any GlobalShortcut, settings: SettingsModel, hud: HUDController, pro: ProModel) {
        self.shortcut = shortcut
        self.settings = settings
        self.hud = hud
        self.pro = pro
    }

    func start() {
        let isRegistered = shortcut.register { [weak self] in
            self?.switchToNextMode()
        }

        guard isRegistered else {
            Logger.dictation.error("Couldn't register the mode shortcut")

            return
        }

        shortcutTitle = shortcut.title
    }

    private func switchToNextMode() {
        settings.settings.mode = settings.settings.mode(after: settings.settings.mode, includingAI: pro.isUnlocked)

        let title = settings.settings.title(of: settings.settings.mode)

        hud.show(HUDMessage(kind: .information, title: String(localized: "Mode: \(title)")))
    }
}
