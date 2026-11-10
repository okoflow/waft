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
        let reply = try await send(api.call(for: request), within: request.deadline)

        guard let secondCall = try api.call(for: request, afterStatus: reply.status) else {
            return try api.answer(from: reply.body(from: api.service))
        }

        let secondReply = try await send(secondCall, within: request.deadline)

        return try api.answer(from: secondReply.body(from: api.service))
    }

    private func send(_ call: APICall<API.Body>, within deadline: Duration) async throws(RewriteError) -> HTTPReply {
        var urlRequest = URLRequest(url: call.url, timeoutInterval: deadline / .seconds(1))
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try Self.encoded(call.body)
        urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")

        for (field, value) in call.headers {
            urlRequest.setValue(value, forHTTPHeaderField: field)
        }

        return try await transport.reply(to: urlRequest, from: api.service)
    }
}
