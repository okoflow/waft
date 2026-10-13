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
        (URLError(.timedOut), RewriteError.timeout),
        (URLError(.cancelled), .timeout),
        (URLError(.serverCertificateUntrusted), .unavailable),
        (URLError(.appTransportSecurityRequiresSecureConnection), .unavailable),
        (URLError(.notConnectedToInternet), .offline),
        (URLError(.cannotConnectToHost), .offline),
        (CocoaError(.fileReadUnknown), .offline),
    ] as [(any Error, RewriteError)])
    func `maps a failed request to a rewrite error`(failure: any Error, error: RewriteError) {
        #expect(RewriteError.failedRequest(failure, to: "Claude") == error)
    }
}
