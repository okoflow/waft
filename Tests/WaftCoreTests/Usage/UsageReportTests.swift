import Foundation
import Testing
@testable import WaftCore

struct UsageReportTests {
    private static let host = UsageHost(appVersion: "1.2.3", systemVersion: "15.1", language: "pt-BR")
    private static let installation = "3f2504e0-4f89-41d3-9a0c-0305e82c3301"
    private static let license = License(email: "buyer@example.com", name: nil)

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
            access: ProAccess(license: Self.license, trialStarted: .fixed, now: .fixed),
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
            "license": "licensed",
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
    func `names a local server`() {
        var settings = Settings(languages: .preferred(by: []))
        settings.modelProvider = .localServer

        let access = ProAccess(license: Self.license, trialStarted: .fixed, now: .fixed)

        #expect(report(access: access, settings: settings).provider == "local")
    }

    @Test(arguments: [(3600, "trial"), (4 * 86400, "expired")] as [(TimeInterval, String)])
    func `names the trial and its end without a license`(elapsed: TimeInterval, license: String) {
        let access = ProAccess(license: nil, trialStarted: .fixed, now: Date.fixed.addingTimeInterval(elapsed))

        #expect(report(access: access).license == license)
    }

    private func report(access: ProAccess, settings: Settings = Settings(languages: .preferred(by: []))) -> UsageReport {
        UsageReport(
            installation: UUID(),
            day: "2026-10-12",
            counts: UsageCounts(),
            host: Self.host,
            settings: settings,
            access: access,
        )
    }
}
