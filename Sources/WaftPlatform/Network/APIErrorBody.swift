import Foundation

struct APIErrorBody: Decodable {
    struct Detail: Decodable {
        let message: String
        let type: String?
        let code: ErrorCode?

        var kind: String {
            let parts = [type, code?.text].compactMap(\.self)
            guard !parts.isEmpty else { return "untyped" }

            return parts.joined(separator: " ")
        }

        var redactedMessage: String {
            message.replacingOccurrences(of: APIErrorBody.secretPattern, with: "sk-…", options: .regularExpression)
        }
    }

    struct ErrorCode: Decodable {
        let text: String

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()

            do {
                text = try container.decode(String.self)
            } catch {
                text = try String(container.decode(Int.self))
            }
        }
    }

    private static let secretPattern = #"sk-[A-Za-z0-9*_\-]+"#

    let error: Detail

    static func detail(in data: Data) -> Detail? {
        guard let body = try? JSONDecoder().decode(APIErrorBody.self, from: data) else { return nil }

        return body.error
    }
}
