import Testing
import WaftCore
@testable import WaftFeatures

struct WritingSettingsPaneTests {
    private static let notes = "com.apple.Notes"

    private let settings = SettingsModel.inMemory()

    @Test
    func `adds an app with the default mode`() {
        settings.settings.mode = .raw
        pane().add(Self.notes)

        #expect(settings.settings.appModes.mode(for: Self.notes) == .raw)
    }

    @Test
    func `keeps the mode of an app that is added again`() {
        settings.settings.appModes.set(.formal, for: Self.notes)
        settings.settings.mode = .raw
        pane().add(Self.notes)

        #expect(settings.settings.appModes.mode(for: Self.notes) == .formal)
    }

    private func pane() -> WritingSettingsPane {
        let shortcuts = GlobalShortcutController.fake(settings: settings)

        return WritingSettingsPane(
            settings: settings,
            apiKeys: PerProvider(claude: APIKeyModel(store: FakeValueStore()), openAI: APIKeyModel(store: FakeValueStore())),
            shortcuts: shortcuts,
            shortcutRecorder: ShortcutRecorder(settings: settings, shortcuts: shortcuts),
            pro: .unlicensed(),
            state: SettingsWindowState(),
        )
    }
}
