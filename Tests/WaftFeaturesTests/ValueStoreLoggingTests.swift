import Testing
@testable import WaftFeatures

struct ValueStoreLoggingTests {
    @Test(arguments: [(Int?.some(3), false, 3), (nil, false, 7), (3, true, 7)])
    func `reads the stored value or else the default when the store is empty or fails to load`(
        stored: Int?,
        isBroken: Bool,
        read: Int,
    ) {
        #expect(FakeValueStore(stored, isBroken: isBroken).read(default: 7) == read)
    }
}
