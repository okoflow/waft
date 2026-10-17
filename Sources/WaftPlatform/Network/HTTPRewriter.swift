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
        var urlRequest = URLRequest(url: call.url, timeoutInterval: request.deadline.timeInterval)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try Self.encoded(call.body)
        urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")

        for (field, value) in call.headers {
            urlRequest.setValue(value, forHTTPHeaderField: field)
        }

        let (data, status) = try await send(urlRequest)
        guard (200 ..< 300).contains(status) else {
            logFailure(status: status, body: data)

            throw RewriteError(httpStatus: status)
        }

        return try api.answer(from: data)
    }

    private func send(_ request: URLRequest) async throws(RewriteError) -> (data: Data, status: Int) {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await transport.data(for: request)
        } catch {
            throw .failedRequest(error, to: api.service)
        }

        guard let http = response as? HTTPURLResponse else { throw .unreadableResponse }

        return (data, http.statusCode)
    }

    private func logFailure(status: Int, body: Data) {
        guard let detail = APIErrorBody.detail(in: body) else {
            Logger.network.error("\(api.service, privacy: .public) answered HTTP \(status, privacy: .public) with no details")

            return
        }

        Logger.network.error(
            """
            \(api.service, privacy: .public) answered HTTP \(status, privacy: .public): \
            \(detail.kind, privacy: .public) \(detail.redactedMessage, privacy: .private)
            """,
        )
    }
}
