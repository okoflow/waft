import Testing
import WaftCore
@testable import WaftFeatures

struct SettingsModelTests {
    @Test
    func `reports a change to the history limits`() {
        var changeCount = 0
        let store = FakeValueStore(Settings(languages: .preferred(by: [])))
        let settings = SettingsModel(store: store, loginItem: FakeLoginItem(), audioInputs: FakeAudioInputProvider())
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
}
