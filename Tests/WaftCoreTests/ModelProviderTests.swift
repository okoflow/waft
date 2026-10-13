import Foundation
import Testing
import WaftCore

struct ModelProviderTests {
    @Test(arguments: [(ModelProvider.localServer, "local"), (.cloud(.claude), "claude"), (.cloud(.openAI), "openai")])
    func `stores a provider by its name`(provider: ModelProvider, name: String) throws {
        let data = try JSONEncoder().encode(provider)

        #expect(String(bytes: data, encoding: .utf8) == "\"\(name)\"")
        #expect(try JSONDecoder().decode(ModelProvider.self, from: data) == provider)
    }

    @Test
    func `refuses to decode an unknown provider`() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ModelProvider.self, from: Data(#""gemini""#.utf8))
        }
    }
}
