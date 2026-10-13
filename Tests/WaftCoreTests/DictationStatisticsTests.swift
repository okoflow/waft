import Foundation
import Testing
import WaftCore

struct DictationStatisticsTests {
    @Test
    func `records a dictation on its date in the calendar's time zone`() throws {
        var tokyo = Calendar.gmt
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        var statistics = DictationStatistics()
        try statistics.record(words: 1, seconds: 1, on: date(2026, 10, 12, hour: 23), calendar: tokyo)

        #expect(Array(statistics.days.keys) == ["2026-10-13"])
    }

    @Test
    func `adds up dictations on the same day`() throws {
        var statistics = DictationStatistics()
        try statistics.record(words: 10, seconds: 4, on: date(2026, 10, 12, hour: 9), calendar: .gmt)
        try statistics.record(words: 5, seconds: 2.5, on: date(2026, 10, 12, hour: 18), calendar: .gmt)
        let day = try #require(statistics.days["2026-10-12"])

        #expect(day.words == 15)
        #expect(day.dictations == 2)
        #expect(day.seconds == 6.5)
    }

    @Test
    func `lists the last days in order with empty days included`() throws {
        var statistics = DictationStatistics()
        try statistics.record(words: 7, seconds: 3, on: date(2026, 10, 10, hour: 12), calendar: .gmt)
        try statistics.record(words: 2, seconds: 1, on: date(2026, 10, 12, hour: 8), calendar: .gmt)
        let daily = try statistics.daily(last: 3, endingOn: date(2026, 10, 12, hour: 20), calendar: .gmt)
        let dates = try [date(2026, 10, 10), date(2026, 10, 11), date(2026, 10, 12)]

        #expect(daily.map(\.date) == dates)
        #expect(daily.map(\.day.words) == [7, 0, 2])
        #expect(daily.map(\.day.dictations) == [1, 0, 1])
    }

    @Test(arguments: [(1, 4), (2, 4), (3, 11), (41, 11), (42, 111)])
    func `totals the words of the last days`(days: Int, words: Int) throws {
        var statistics = DictationStatistics()
        try statistics.record(words: 100, seconds: 60, on: date(2026, 9, 1), calendar: .gmt)
        try statistics.record(words: 7, seconds: 3, on: date(2026, 10, 10), calendar: .gmt)
        try statistics.record(words: 4, seconds: 2, on: date(2026, 10, 12), calendar: .gmt)
        let total = try statistics.total(last: days, endingOn: date(2026, 10, 12, hour: 23), calendar: .gmt)

        #expect(total.words == words)
    }

    @Test(arguments: [(12, 3), (13, 3), (14, 0), (11, 2), (9, 1)])
    func `counts the days in a row up to today or yesterday`(today: Int, streak: Int) throws {
        var statistics = DictationStatistics()

        for day in [8, 10, 11, 12] {
            try statistics.record(words: 1, seconds: 1, on: date(2026, 10, day, hour: 9), calendar: .gmt)
        }

        #expect(try statistics.streak(endingOn: date(2026, 10, today, hour: 20), calendar: .gmt) == streak)
    }

    @Test(arguments: [(40, 60.0, 0.0), (80, 60, 60), (200, 90, 210)])
    func `measures the time saved over typing`(words: Int, seconds: Double, saved: Double) {
        var day = DictationStatistics.Day()
        day.words = words
        day.seconds = seconds

        #expect(day.savedOverTyping == .seconds(saved))
    }

    @Test(arguments: [(0, 0.0, Int?.none), (90, 60, 90), (100, 45, 133)])
    func `measures the words a minute`(words: Int, seconds: Double, wordsPerMinute: Int?) {
        var day = DictationStatistics.Day()
        day.words = words
        day.seconds = seconds

        #expect(day.wordsPerMinute == wordsPerMinute)
    }

    @Test
    func `totals every recorded day`() throws {
        var statistics = DictationStatistics()
        try statistics.record(words: 100, seconds: 60, on: date(2025, 1, 1), calendar: .gmt)
        try statistics.record(words: 7, seconds: 3, on: date(2026, 10, 12), calendar: .gmt)
        try statistics.record(words: 4, seconds: 2, on: date(2026, 10, 12, hour: 18), calendar: .gmt)

        #expect(statistics.allTime.words == 111)
        #expect(statistics.allTime.dictations == 3)
        #expect(statistics.allTime.seconds == 65)
    }

    @Test
    func `decodes the stored format`() throws {
        let json = #"{"days":{"2026-10-12":{"words":15,"dictations":2,"seconds":6.5}}}"#
        let statistics = try JSONDecoder().decode(DictationStatistics.self, from: Data(json.utf8))
        let day = try #require(statistics.days["2026-10-12"])

        #expect(day.words == 15)
        #expect(day.dictations == 2)
        #expect(day.seconds == 6.5)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) throws -> Date {
        try #require(Calendar.gmt.date(from: DateComponents(year: year, month: month, day: day, hour: hour)))
    }
}
