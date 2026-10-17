import Testing
@testable import WaftFeatures

struct APIKeyModelTests {
    @Test(arguments: [nil, "existing-key"] as [String?])
    func `saves the trimmed draft and clears it`(stored: String?) {
        let store = FakeValueStore(stored)
        let apiKey = APIKeyModel(store: store)
        apiKey.draft = "  my-api-key\n"
        apiKey.saveDraft()

        #expect(store.value == "my-api-key")
        #expect(apiKey.draft.isEmpty)
        #expect(apiKey.isSet)
    }

    @Test(arguments: [nil, "existing-key"] as [String?])
    func `preserves the draft and stored state when saving fails`(stored: String?) {
        let store = FakeValueStore(stored, failsSaving: true)
        let apiKey = APIKeyModel(store: store)
        let draft = "  replacement-key\n"
        apiKey.draft = draft
        apiKey.saveDraft()

        #expect(apiKey.draft == draft)
        #expect(apiKey.canSaveDraft)
        #expect(apiKey.isSet == (stored != nil))
        #expect(store.value == stored)
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
