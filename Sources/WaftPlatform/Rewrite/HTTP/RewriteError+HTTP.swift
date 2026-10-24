import Foundation
import os
import WaftCore

extension RewriteError {
    init(httpStatus: Int) {
        switch httpStatus {
        case 401, 403: self = .rejectedKey
        case 404: self = .unavailable
        case 429: self = .rateLimited
        default: self = .serviceUnavailable
        }
    }

    static func failedRequest(_ error: any Error, to service: String) -> RewriteError {
        guard let error = error as? URLError else {
            let errorType = String(describing: type(of: error))

            Logger.network.error("The request to \(service, privacy: .public) failed: \(errorType, privacy: .public)")

            return .offline
        }
        guard error.code != .cancelled else { return .timeout }

        let code = error.code.rawValue

        Logger.network.error("The request to \(service, privacy: .public) failed: URLError \(code, privacy: .public)")

        return switch error.code {
        case .timedOut:
            .timeout
        case .secureConnectionFailed, .serverCertificateUntrusted, .serverCertificateHasBadDate,
             .serverCertificateHasUnknownRoot, .serverCertificateNotYetValid, .appTransportSecurityRequiresSecureConnection:
            .unavailable
        default:
            .offline
        }
    }
}
