import Foundation
import Testing
import WaftCore
@testable import WaftPlatform

struct RewriteErrorHTTPTests {
    @Test(arguments: [
        (401, RewriteError.rejectedKey),
        (403, .rejectedKey),
        (404, .unavailable),
        (429, .rateLimited),
        (500, .serviceUnavailable),
        (503, .serviceUnavailable),
    ])
    func `maps an HTTP status to a rewrite error`(status: Int, error: RewriteError) {
        #expect(RewriteError(httpStatus: status) == error)
    }

    @Test(arguments: [
        (URLError.Code.timedOut, RewriteError.timeout),
        (.cancelled, .timeout),
        (.serverCertificateUntrusted, .unavailable),
        (.appTransportSecurityRequiresSecureConnection, .unavailable),
        (.notConnectedToInternet, .offline),
        (.cannotConnectToHost, .offline),
    ])
    func `maps a failed request to a rewrite error`(code: URLError.Code, error: RewriteError) {
        #expect(RewriteError.failedRequest(URLError(code), to: "Claude") == error)
    }

    @Test
    func `treats a request that fails without a URL error as offline`() {
        #expect(RewriteError.failedRequest(CocoaError(.fileReadUnknown), to: "Claude") == .offline)
    }
}
