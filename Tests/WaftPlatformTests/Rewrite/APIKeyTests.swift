import Testing
import WaftCore
@testable import WaftPlatform

struct APIKeyTests {
    @Test(arguments: [FakeValueStore<String>(nil), FakeValueStore(""), FakeValueStore("sk-test", isBroken: true)])
    func `reports a missing key when the store has none or cannot read it`(store: FakeValueStore<String>) {
        #expect(throws: RewriteError.missingKey) {
            try APIKey.load(from: store)
        }
    }
}
