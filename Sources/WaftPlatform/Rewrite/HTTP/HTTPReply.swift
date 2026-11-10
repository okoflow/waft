import Foundation
import os
import WaftCore

struct HTTPReply {
    let status: Int
    let data: Data

    func body(from service: String) throws(RewriteError) -> Data {
        guard (200 ..< 300).contains(status) else {
            Logger.network.error("\(service, privacy: .public) answered HTTP \(status, privacy: .public)")

            throw RewriteError(httpStatus: status)
        }

        return data
    }
}
