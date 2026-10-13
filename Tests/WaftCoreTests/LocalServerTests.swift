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
}
