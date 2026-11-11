import Foundation
import Testing
import WaftCore
@testable import WaftPlatform

struct HTTPUsageReportSenderTests {
    private static let report = UsageReport(
        installation: UUID(),
        day: "2026-10-12",
        counts: UsageCounts(),
        host: UsageHost(appVersion: "1.2.3", systemVersion: "15.1", language: "en"),
        settings: Settings(languages: .preferred(by: [])),
        access: ProAccess(license: nil, trialStarted: Date(), now: Date()),
    )

    @Test
    func `posts the report as JSON to the usage service`() async throws {
        let transport = FakeHTTPTransport(.status(204))

        try await HTTPUsageReportSender(transport: transport).send(Self.report)

        let request = try #require(transport.requests.first)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        #expect(transport.requests.count == 1)
        #expect(request.url?.absoluteString == "https://api.waft.okoflow.com/usage")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "content-type") == "application/json")
        #expect(try encoder.encode(Self.report) == request.httpBody)
    }

    @Test(arguments: [FakeHTTPTransport.Reply.status(400), .failure(URLError(.notConnectedToInternet))])
    func `fails when the service refuses the report or is out of reach`(reply: FakeHTTPTransport.Reply) async {
        let sender = HTTPUsageReportSender(transport: FakeHTTPTransport(reply))

        await #expect(throws: RewriteError.self) {
            try await sender.send(Self.report)
        }
    }
}
