import Testing
import WaftCore
@testable import WaftFeatures

struct SettingsModelTests {
    private static var saved: Settings {
        var settings = Settings(languages: .preferred(by: ["de"]))
        settings.mode = .formal
        settings.playsSounds = false

        return settings
    }

    @Test
    func `loads the saved settings`() {
        #expect(model(FakeValueStore(Self.saved)).settings == Self.saved)
    }

    @Test
    func `starts from the defaults when the saved settings are unreadable and saves over them with the first change`() {
        let store = FakeValueStore(Self.saved, isBroken: true)
        let settings = model(store)

        #expect(settings.settings.mode != .formal)
        #expect(settings.settings.playsSounds)
        #expect(store.value == Self.saved)

        settings.settings.historyLimit = 100

        #expect(store.value == settings.settings)
    }

    @Test
    func `keeps a change in memory when the settings cannot be saved`() {
        let store = FakeValueStore(Self.saved, failsSaving: true)
        let settings = model(store)

        settings.settings.mode = .clean

        #expect(settings.settings.mode == .clean)
        #expect(store.value == Self.saved)
    }

    @Test
    func `reports a change to the history limits`() {
        var changeCount = 0
        let store = FakeValueStore(Settings(languages: .preferred(by: [])))
        let settings = model(store)
        settings.onHistoryLimitsChange = { changeCount += 1 }

        settings.settings.historyRetention = .week
        settings.settings.historyLimit = 100
        settings.settings.playsSounds = false

        #expect(changeCount == 2)
        #expect(store.value == settings.settings)
    }

    @Test
    func `reports a change to the enabled languages but not to the pinned one`() {
        var changeCount = 0
        let settings = SettingsModel.inMemory()
        settings.onLanguagesChange = { changeCount += 1 }

        settings.settings.languages = settings.settings.languages.adding(.german)
        settings.settings.languages = settings.settings.languages.pinning(.german)

        #expect(changeCount == 1)
    }

    @Test
    func `reports a change to sharing usage data`() {
        var changeCount = 0
        let settings = SettingsModel.inMemory()
        settings.onUsageSharingChange = { changeCount += 1 }

        settings.sharesUsage = false
        settings.sharesUsage = false
        settings.sharesUsage = true

        #expect(changeCount == 2)
        #expect(settings.settings.usageSharing == .allowed)
    }

    private func model(_ store: FakeValueStore<Settings>) -> SettingsModel {
        SettingsModel(store: store, loginItem: FakeLoginItem(), audioInputs: FakeAudioInputProvider())
    }
}
