import Foundation
import os
import WaftCore

enum ResponseDecoder {
    static func decode<Value: Decodable>(_: Value.Type, from data: Data, sentBy service: String) throws(RewriteError) -> Value {
        do {
            return try JSONDecoder().decode(Value.self, from: data)
        } catch {
            let reason = cause(of: error)
            Logger.network.error("Couldn't decode the answer of \(service, privacy: .public): \(reason, privacy: .public)")

            throw .unreadableResponse
        }
    }

    private static func cause(of error: any Error) -> String {
        guard let error = error as? DecodingError else { return String(describing: type(of: error)) }

        return switch error {
        case let .keyNotFound(key, context): "missing \(path(context.codingPath + [key]))"
        case let .typeMismatch(_, context): "unexpected type at \(path(context.codingPath))"
        case let .valueNotFound(_, context): "missing value at \(path(context.codingPath))"
        case let .dataCorrupted(context): "unreadable data at \(path(context.codingPath))"
        @unknown default: "an unknown decoding failure"
        }
    }

    private static func path(_ codingPath: [any CodingKey]) -> String {
        guard !codingPath.isEmpty else { return "the top level" }

        return codingPath.map(\.stringValue).joined(separator: ".")
    }
}
