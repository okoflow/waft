package import WaftCore
import Foundation
import Observation
import os

@Observable
package final class SettingsModel {
    package var settings: Settings {
        didSet { settingsDidChange(from: oldValue) }
    }

    private(set) var microphones: [AudioInputDevice] = []

    @ObservationIgnored var onLanguagesChange: (() -> Void)?
    @ObservationIgnored var onSpeechModelChange: (() -> Void)?
    @ObservationIgnored var onHistoryLimitsChange: (() -> Void)?
    @ObservationIgnored var onShortcutsChange: (() -> Void)?

    private var isLoginItemEnabled: Bool

    private let store: any ValueStore<Settings>
    private let loginItem: any LoginItem
    private let audioInputs: any AudioInputProvider

    var launchesAtLogin: Bool {
        get { isLoginItemEnabled }

        set {
            do {
                try loginItem.setEnabled(newValue)
            } catch {
                Logger.settings.error("Couldn't change the login item: \(error.logDescription, privacy: .public)")
            }

            isLoginItemEnabled = loginItem.isEnabled
        }
    }

    init(store: any ValueStore<Settings>, loginItem: any LoginItem, audioInputs: any AudioInputProvider) {
        self.store = store
        self.loginItem = loginItem
        self.audioInputs = audioInputs
        settings = store.read(default: Settings(languages: .preferred(by: Locale.preferredLanguages)))
        isLoginItemEnabled = loginItem.isEnabled
    }

    func refreshMicrophones() {
        microphones = audioInputs.inputDevices()
    }

    private func settingsDidChange(from oldValue: Settings) {
        guard settings != oldValue else { return }

        store.write(settings)

        if settings.languages.languages != oldValue.languages.languages {
            onLanguagesChange?()
        }

        if settings.speechModel != oldValue.speechModel {
            onSpeechModelChange?()
        }

        if (settings.historyRetention, settings.historyLimit) != (oldValue.historyRetention, oldValue.historyLimit) {
            onHistoryLimitsChange?()
        }

        if settings.shortcuts != oldValue.shortcuts {
            onShortcutsChange?()
        }
    }
}
