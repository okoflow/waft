import Foundation
import Testing
import WaftCore

struct LocalServerTests {
    @Test(arguments: [
        (#"{}"#, LocalServer()),
        (#"{"baseURL":42,"model":"qwen"}"#, LocalServer(model: "qwen")),
        (
            #"{"baseURL":"http://localhost:1234/v1","model":"qwen"}"#,
            LocalServer(baseURL: "http://localhost:1234/v1", model: "qwen"),
        ),
    ])
    func `decodes leniently`(json: String, expected: LocalServer) throws {
        #expect(try JSONDecoder().decode(LocalServer.self, from: Data(json.utf8)) == expected)
    }

    @Test(arguments: [
        ("http://localhost:11434/v1", true),
        ("http://127.0.0.1:1234/v1", true),
        ("http://[::1]:8080/v1", true),
        ("  http://LOCALHOST:1337/v1/ ", true),
        ("http://ollama.localhost/v1", true),
        ("http://192.168.1.20:11434/v1", false),
        ("https://models.example.com/v1", false),
        ("", true),
    ])
    func `tells a server on this Mac from one elsewhere`(baseURL: String, isOnThisMac: Bool) {
        #expect(LocalServer(baseURL: baseURL).isOnThisMac == isOnThisMac)
    }
}
