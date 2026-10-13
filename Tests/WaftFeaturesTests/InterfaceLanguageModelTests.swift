import Testing
import WaftCore
@testable import WaftFeatures

struct InterfaceLanguageModelTests {
    @Test
    func `saves a choice and asks for a relaunch until it is undone`() {
        let store = FakeValueStore("de")
        let interfaceLanguage = InterfaceLanguageModel(store: store, lifecycle: FakeAppLifecycle())

        #expect(interfaceLanguage.chosen == "de")
        #expect(!interfaceLanguage.needsRelaunch)

        interfaceLanguage.chosen = nil

        #expect(store.value == nil)
        #expect(interfaceLanguage.needsRelaunch)

        interfaceLanguage.chosen = "de"

        #expect(store.value == "de")
        #expect(!interfaceLanguage.needsRelaunch)
    }
}

private final class FakeAppLifecycle: AppLifecycle {
    func relaunch() {}

    func quit() {}
}
