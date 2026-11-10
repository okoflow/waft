import Foundation
import WaftCore

protocol RewriteAPI: Sendable {
    associatedtype Body: Encodable

    var service: String { get }

    func call(for request: RewriteRequest) throws(RewriteError) -> APICall<Body>
    func call(for request: RewriteRequest, afterStatus status: Int) throws(RewriteError) -> APICall<Body>?
    func answer(from data: Data) throws(RewriteError) -> String
}

extension RewriteAPI {
    func call(for _: RewriteRequest, afterStatus _: Int) -> APICall<Body>? {
        nil
    }

    func decoded<Response: Decodable>(_ type: Response.Type, from data: Data) throws(RewriteError) -> Response {
        try ResponseDecoder.decode(type, from: data, sentBy: service)
    }
}
