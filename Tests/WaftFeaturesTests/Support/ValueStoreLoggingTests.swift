import Testing
@testable import WaftFeatures

struct ValueStoreLoggingTests {
    @Test(arguments: [false, true])
    func `reports whether the value was deleted`(failsDeleting: Bool) {
        let store = FakeValueStore(3, failsDeleting: failsDeleting)

        #expect(store.remove() == !failsDeleting)
        #expect(store.value == (failsDeleting ? 3 : nil))
    }

    @Test(arguments: [false, true])
    func `reports whether a value was saved`(failsSaving: Bool) {
        let store = FakeValueStore(3, failsSaving: failsSaving)

        #expect(store.write(7) == !failsSaving)
        #expect(store.value == (failsSaving ? 3 : 7))
    }

    @Test(arguments: [(Int?.some(3), false, 3), (nil, false, 7), (3, true, 7)])
    func `reads the stored value or else the default when the store is empty or fails to load`(
        stored: Int?,
        isBroken: Bool,
        read: Int,
    ) {
        #expect(FakeValueStore(stored, isBroken: isBroken).read(default: 7) == read)
    }
}
