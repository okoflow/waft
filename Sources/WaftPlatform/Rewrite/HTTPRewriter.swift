import Foundation
import os
import WaftCore

struct HTTPRewriter<API: RewriteAPI>: TextRewriter {
    private let api: API
    private let transport: any HTTPTransport

    init(api: API, transport: any HTTPTransport) {
        self.api = api
        self.transport = transport
    }

    private static func encoded(_ body: API.Body) throws(RewriteError) -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        do {
            return try encoder.encode(body)
        } catch {
            Logger.network.error("Couldn't encode the request: \(String(describing: type(of: error)), privacy: .public)")

            throw .unavailable
        }
    }

    func rewrite(_ request: RewriteRequest) async throws(RewriteError) -> String {
        let call = try api.call(for: request)

        var urlRequest = URLRequest(url: call.url, timeoutInterval: request.deadline / .seconds(1))
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try Self.encoded(call.body)
        urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")

        for (field, value) in call.headers {
            urlRequest.setValue(value, forHTTPHeaderField: field)
        }

        let data = try await transport.body(for: urlRequest, from: api.service)

        return try api.answer(from: data)
    }
}
