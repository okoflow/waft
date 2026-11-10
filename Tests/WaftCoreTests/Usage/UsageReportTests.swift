import Foundation
import Testing
@testable import WaftCore

struct UsageReportTests {
    private static let host = UsageHost(appVersion: "1.2.3", systemVersion: "15.1", language: "pt-BR")
    private static let installation = "3f2504e0-4f89-41d3-9a0c-0305e82c3301"

    @Test
    func `encodes the fields the usage service accepts and nothing else`() throws {
        var settings = Settings(languages: .preferred(by: []))
        settings.speechModel = .accurate
        settings.modelProvider = .cloud(.openAI)

        var counts = UsageCounts()
        counts.count(.dictation(.formal))

        let installation = try #require(UUID(uuidString: Self.installation))
        let report = UsageReport(
            installation: installation,
            day: "2026-10-12",
            counts: counts,
            host: Self.host,
            settings: settings,
            access: ProAccess(license: nil, trialStarted: Date(), now: Date()),
        )

        let encoded = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(report)) as? [String: Any])
        let fields = encoded.filter { $0.key != "counts" } as? [String: String]
        let sentCounts = try #require(encoded["counts"] as? [String: Int])

        #expect(fields == [
            "installation": Self.installation,
            "day": "2026-10-12",
            "appVersion": "1.2.3",
            "systemVersion": "15.1",
            "language": "pt-BR",
            "speechModel": "accurate",
            "provider": "openai",
            "license": "beta",
        ])
        #expect(sentCounts.filter { $0.value > 0 } == ["formalDictations": 1])
        #expect(sentCounts.keys.sorted() == [
            "cleanDictations",
            "customDictations",
            "fileTranscriptions",
            "formalDictations",
            "lightDictations",
            "rawDictations",
            "selectionActions",
            "translateDictations",
            "translations",
            "voiceEdits",
        ])
    }

    @Test
    func `names a local server and a license`() {
        var settings = Settings(languages: .preferred(by: []))
        settings.modelProvider = .localServer

        let license = License(email: "buyer@example.com", name: nil)
        let report = UsageReport(
            installation: UUID(),
            day: "2026-10-12",
            counts: UsageCounts(),
            host: Self.host,
            settings: settings,
            access: ProAccess(license: license, trialStarted: Date(), now: Date()),
        )

        #expect(report.provider == "local")
        #expect(report.license == "licensed")
    }
}
