import Foundation
import Testing

extension Encodable {
    func jsonObject() throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(self)) as? [String: Any])
    }
}
