import WaftCore
@testable import WaftFeatures

extension SettingsModel {
    static func inMemory(usageSharing: UsageSharing = .undecided) -> SettingsModel {
        var settings = Settings(languages: .preferred(by: []))
        settings.usageSharing = usageSharing

        return SettingsModel(
            store: FakeValueStore(settings),
            loginItem: FakeLoginItem(),
            audioInputs: FakeAudioInputProvider(),
        )
    }
}
