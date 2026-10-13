import Foundation
import WaftCore

protocol RewriteAPI: Sendable {
    associatedtype Body: Encodable

    var service: String { get }

    func call(for request: RewriteRequest) throws(RewriteError) -> APICall<Body>
    func answer(from data: Data) throws(RewriteError) -> String
}

extension RewriteAPI {
    func decoded<Response: Decodable>(_ type: Response.Type, from data: Data) throws(RewriteError) -> Response {
        try ResponseDecoder.decode(type, from: data, sentBy: service)
    }
}
