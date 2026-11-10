import Foundation
import Testing
@testable import WaftCore

struct UsageLogTests {
    @Test
    func `counts each event on its date in the calendar's time zone`() throws {
        var tokyo = Calendar.gmt
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))

        var log = UsageLog(installation: UUID())
        try log.record(.dictation(.clean), on: date(2026, 10, 12, hour: 23), calendar: tokyo)
        try log.record(.dictation(.clean), on: date(2026, 10, 12, hour: 23), calendar: tokyo)
        try log.record(.dictation(.custom(UUID())), on: date(2026, 10, 12, hour: 23), calendar: tokyo)
        try log.record(.voiceEdit, on: date(2026, 10, 12, hour: 23), calendar: tokyo)

        let counts = try #require(log.days["2026-10-13"]).counts

        #expect(Array(log.days.keys) == ["2026-10-13"])
        #expect(counts.cleanDictations == 2)
        #expect(counts.customDictations == 1)
        #expect(counts.voiceEdits == 1)
        #expect(counts.rawDictations == 0)
    }

    @Test
    func `lists a day as unsent until its counts are sent and again once they change`() throws {
        let day = try date(2026, 10, 12, hour: 9)

        var log = UsageLog(installation: UUID())
        log.startDay(on: day, calendar: .gmt)

        #expect(log.unsentDays == ["2026-10-12"])

        log.markSent("2026-10-12", with: UsageCounts())

        #expect(log.unsentDays.isEmpty)

        log.record(.translation, on: day, calendar: .gmt)

        #expect(log.unsentDays == ["2026-10-12"])
    }

    @Test
    func `keeps a day unsent when its counts changed while they were being sent`() throws {
        let day = try date(2026, 10, 12, hour: 9)

        var log = UsageLog(installation: UUID())
        log.startDay(on: day, calendar: .gmt)
        log.record(.fileTranscription, on: day, calendar: .gmt)
        log.markSent("2026-10-12", with: UsageCounts())

        #expect(log.unsentDays == ["2026-10-12"])
    }

    @Test
    func `starts a day by dropping the sent days and the ones older than a week`() throws {
        var log = UsageLog(installation: UUID())
        try log.record(.selectionAction, on: date(2026, 10, 1), calendar: .gmt)
        try log.record(.selectionAction, on: date(2026, 10, 9), calendar: .gmt)
        try log.record(.selectionAction, on: date(2026, 10, 10), calendar: .gmt)
        try log.record(.selectionAction, on: date(2026, 10, 12), calendar: .gmt)

        let sent = try #require(log.days["2026-10-10"]).counts
        log.markSent("2026-10-10", with: sent)
        log.markSent("2026-10-12", with: sent)

        try log.startDay(on: date(2026, 10, 12, hour: 8), calendar: .gmt)

        #expect(log.days.keys.sorted() == ["2026-10-09", "2026-10-12"])
        #expect(log.unsentDays == ["2026-10-09"])
    }

    @Test
    func `survives encoding with its installation and days`() throws {
        var log = UsageLog(installation: UUID())
        try log.record(.dictation(.raw), on: date(2026, 10, 12), calendar: .gmt)

        let decoded = try JSONDecoder().decode(UsageLog.self, from: JSONEncoder().encode(log))

        #expect(decoded == log)
    }

    @Test
    func `decodes a log saved with other counters and keeps its installation and days`() throws {
        let installation = UUID()

        let json = #"""
        {"installation":"\#(installation.uuidString)","days":{
         "2026-10-10":{"counts":{"cleanDictations":2,"retiredCounter":9},"isSent":true},
         "2026-10-11":{"counts":{"voiceEdits":"many","translations":1}},
         "2026-10-12":"bogus"}}
        """#

        let log = try JSONDecoder().decode(UsageLog.self, from: Data(json.utf8))

        let sent = try #require(log.days["2026-10-10"])
        let unsent = try #require(log.days["2026-10-11"])

        #expect(log.installation == installation)
        #expect(log.days.keys.sorted() == ["2026-10-10", "2026-10-11"])
        #expect(log.unsentDays == ["2026-10-11"])
        #expect(sent.counts.cleanDictations == 2)
        #expect(sent.counts.fileTranscriptions == 0)
        #expect(unsent.counts.voiceEdits == 0)
        #expect(unsent.counts.translations == 1)
    }

    @Test
    func `rejects a log without its installation`() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(UsageLog.self, from: Data(#"{"days":{}}"#.utf8))
        }
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) throws -> Date {
        try #require(Calendar.gmt.date(from: DateComponents(year: year, month: month, day: day, hour: hour)))
    }
}
