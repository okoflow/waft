import Foundation
import Testing
@testable import WaftPlatform

struct URLSessionConfigurationAnonymousTests {
    @Test
    func `replaces the headers that describe the Mac and its languages`() throws {
        let headers = try #require(URLSessionConfiguration.anonymous.httpAdditionalHeaders as? [String: String])

        #expect(headers == ["User-Agent": "Waft", "Accept-Language": "en"])
    }
}
