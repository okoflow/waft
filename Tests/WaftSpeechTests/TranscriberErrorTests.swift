import Testing
import WaftCore
@testable import WaftSpeech

struct TranscriberErrorTests {
    @Test
    func `names a missing speech model by its title`() {
        #expect(TranscriberError.modelMissing(.accurate).errorDescription == "The speech model Accurate isn't downloaded.")
    }
}
