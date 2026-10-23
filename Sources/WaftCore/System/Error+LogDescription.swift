import Foundation

extension Error {
    package var logDescription: String {
        let cause = self as NSError

        return "\(cause.domain) \(cause.code)"
    }
}
