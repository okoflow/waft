import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct UsageReporterTests {
    private static let host = UsageHost(appVersion: "1.2.3", systemVersion: "15.1", language: "en")

    private let store = FakeValueStore<UsageLog>()
    private let sender = FakeUsageReportSender()

    @Test(arguments: [UsageSharing.undecided, .declined])
    func `keeps no log and sends nothing without an agreement`(sharing: UsageSharing) {
        let reporter = reporter(settings: .inMemory(usageSharing: sharing))

        reporter.start()
        reporter.record(.voiceEdit)

        #expect(store.value == nil)
        #expect(sender.reports.isEmpty)
    }

    @Test
    func `keeps no log in a build without a version`() {
        let reporter = reporter(settings: .inMemory(usageSharing: .allowed), host: nil)

        reporter.start()
        reporter.record(.voiceEdit)

        #expect(store.value == nil)
    }

    @Test
    func `sends the day once it starts and marks it sent`() async throws {
        let settings = SettingsModel.inMemory(usageSharing: .allowed)
        let reporter = reporter(settings: settings)

        reporter.start()

        #expect(await Poll.until(timeout: .seconds(5)) { store.value?.unsentDays.isEmpty == true })

        let log = try #require(store.value)
        let day = try #require(log.days.keys.first)

        #expect(sender.reports == [report(of: log, day: day, counts: UsageCounts(), settings: settings)])
    }

    @Test
    func `sends a day again with what was recorded after it was sent`() async throws {
        let settings = SettingsModel.inMemory(usageSharing: .allowed)
        let reporter = reporter(settings: settings)

        reporter.start()

        #expect(await Poll.until(timeout: .seconds(5)) { store.value?.unsentDays.isEmpty == true })

        reporter.record(.dictation(.clean))

        let log = try #require(store.value)
        let day = try #require(log.unsentDays.first)
        let counts = try #require(log.days[day]).counts

        reporter.start()

        #expect(await Poll.until(timeout: .seconds(5)) { sender.reports.count == 2 })
        #expect(counts.cleanDictations == 1)
        #expect(sender.reports.last == report(of: log, day: day, counts: counts, settings: settings))
    }

    @Test
    func `keeps a day unsent when sending fails`() async {
        var finishedRounds = 0

        let reporter = reporter(settings: .inMemory(usageSharing: .allowed), sender: FakeUsageReportSender(fails: true)) { _ in
            finishedRounds += 1

            return false
        }

        reporter.start()
        reporter.record(.translation)

        #expect(await Poll.until(timeout: .seconds(5)) { finishedRounds == 1 })
        #expect(store.value?.days.values.map(\.counts.translations) == [1])
        #expect(store.value?.unsentDays.count == 1)
    }

    @Test
    func `forgets the log when sharing is turned off and starts a new installation when it is back on`() async throws {
        let settings = SettingsModel.inMemory(usageSharing: .allowed)
        let reporter = reporter(settings: settings)

        reporter.start()

        #expect(await Poll.until(timeout: .seconds(5)) { store.value != nil })

        let first = try #require(store.value).installation

        settings.sharesUsage = false
        reporter.start()
        reporter.record(.voiceEdit)

        #expect(store.value == nil)

        settings.sharesUsage = true
        reporter.start()

        #expect(await Poll.until(timeout: .seconds(5)) { store.value != nil })
        #expect(store.value?.installation != first)
    }

    private func reporter(settings: SettingsModel, host: UsageHost? = host) -> UsageReporter {
        reporter(settings: settings, sender: sender, host: host)
    }

    private func reporter(
        settings: SettingsModel,
        sender: FakeUsageReportSender,
        host: UsageHost? = host,
        waitForInterval: @escaping (Duration) async -> Bool = { _ in false },
    ) -> UsageReporter {
        UsageReporter(
            store: store,
            sender: sender,
            settings: settings,
            pro: .unlicensed(),
            host: host,
            waitForInterval: waitForInterval,
        )
    }

    private func report(of log: UsageLog, day: String, counts: UsageCounts, settings: SettingsModel) -> UsageReport {
        UsageReport(
            installation: log.installation,
            day: day,
            counts: counts,
            host: Self.host,
            settings: settings.settings,
            access: ProModel.unlicensed().access,
        )
    }
}
