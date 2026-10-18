import Testing
import WaftCore

struct PerProviderTests {
    @Test
    func `builds the value of each provider from the provider`() {
        #expect(PerProvider { $0 } == PerProvider(claude: CloudProvider.claude, openAI: .openAI))
    }
}
