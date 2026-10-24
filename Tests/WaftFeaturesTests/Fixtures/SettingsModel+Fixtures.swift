import WaftCore
@testable import WaftFeatures

extension SettingsModel {
    static func inMemory() -> SettingsModel {
        SettingsModel(
            store: FakeValueStore(Settings(languages: .preferred(by: []))),
            loginItem: FakeLoginItem(),
            audioInputs: FakeAudioInputProvider(),
        )
    }
}
