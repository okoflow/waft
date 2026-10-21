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

    @Test(arguments: ["http://localhost:11434/v1", " http://localhost:11434/v1/ ", "http://localhost:11434/v1///"])
    func `joins the path without double slashes`(baseURL: String) throws {
        let url = try LocalServer(baseURL: baseURL).url(appending: "/models")

        #expect(url.absoluteString == "http://localhost:11434/v1/models")
    }

    @Test(arguments: ["http://local host:1234/v1", "localhost:1234/v1", "", " "])
    func `rejects a base URL that names no server`(baseURL: String) {
        #expect(throws: RewriteError.unavailable) {
            try LocalServer(baseURL: baseURL).url(appending: "/models")
        }
    }
}
