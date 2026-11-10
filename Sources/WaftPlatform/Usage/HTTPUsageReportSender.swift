package import WaftCore
import Foundation

package struct HTTPUsageReportSender: UsageReportSender {
    private static let endpoint = URL(literal: "https://api.waft.okoflow.com/usage")
    private static let timeout: TimeInterval = 15
    private static let service = "The usage service"

    private let transport: any HTTPTransport

    package init() {
        self.init(transport: URLSession(configuration: .anonymous))
    }

    init(transport: any HTTPTransport) {
        self.transport = transport
    }

    package func send(_ report: UsageReport) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        var request = URLRequest(url: Self.endpoint, timeoutInterval: Self.timeout)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(report)
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        _ = try await transport.body(for: request, from: Self.service)
    }
}
