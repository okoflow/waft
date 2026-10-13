import Testing
@testable import WaftFeatures

struct APIKeyModelTests {
    @Test
    func `saves the trimmed draft and clears it`() {
        let store = FakeValueStore<String>()
        let apiKey = APIKeyModel(store: store)
        apiKey.draft = "  my-api-key\n"
        apiKey.saveDraft()

        #expect(store.value == "my-api-key")
        #expect(apiKey.draft.isEmpty)
        #expect(apiKey.isSet)
    }

    @Test(arguments: ["", " \n\t"])
    func `ignores a blank draft`(draft: String) {
        let store = FakeValueStore<String>()
        let apiKey = APIKeyModel(store: store)
        apiKey.draft = draft
        apiKey.saveDraft()

        #expect(store.value == nil)
        #expect(!apiKey.isSet)
    }

    @Test
    func `removes the stored key`() {
        let store = FakeValueStore("my-api-key")
        let apiKey = APIKeyModel(store: store)
        apiKey.remove()

        #expect(store.value == nil)
        #expect(!apiKey.isSet)
    }
}
