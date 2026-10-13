import Foundation
import Testing
import WaftCore
@testable import WaftPlatform

struct LocalServerURLTests {
    @Test(arguments: ["http://localhost:11434/v1", " http://localhost:11434/v1/ ", "http://localhost:11434/v1///"])
    func `joins the path without double slashes`(baseURL: String) throws {
        let url = try LocalServer(baseURL: baseURL).url(appending: "/models")

        #expect(url.absoluteString == "http://localhost:11434/v1/models")
    }

    @Test
    func `rejects a base URL that is not a URL`() {
        #expect(throws: RewriteError.unavailable) {
            try LocalServer(baseURL: "http://local host:1234/v1").url(appending: "/models")
        }
    }
}
