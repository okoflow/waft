import Foundation

extension Error {
    var logDescription: String {
        let cause = self as NSError

        return "\(cause.domain) \(cause.code)"
    }
}
