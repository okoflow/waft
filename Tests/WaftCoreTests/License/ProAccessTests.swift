import Foundation
import Testing
@testable import WaftCore

struct ProAccessTests {
    @Test
    func `unlocks everything for a license holder`() {
        let license = License(email: "ann@example.com", name: nil)

        let access = ProAccess(license: license, trialStarted: .distantPast, now: .now)

        #expect(access.status == .licensed(license))
        #expect(access.isUnlocked)
    }

    @Test(arguments: [(3600.0, ProAccess.Status.trial, true), (4 * 86400, .expired, false)])
    func `runs a trial without a license`(elapsed: TimeInterval, status: ProAccess.Status, isUnlocked: Bool) {
        let access = ProAccess(license: nil, trialStarted: .fixed, now: Date.fixed.addingTimeInterval(elapsed))

        #expect(access.status == status)
        #expect(access.isUnlocked == isUnlocked)
    }

    @Test(arguments: [(9, 0), (10, 15), (10, 23)])
    func `ends the trial three days after the day it started`(day: Int, hour: Int) throws {
        let start = try #require(Calendar.gmt.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour)))
        let end = try #require(Calendar.gmt.date(from: DateComponents(year: 2026, month: 10, day: day + 3)))

        #expect(ProAccess.trialEnd(startedOn: start, now: start, calendar: .gmt) == end)
    }

    @Test(arguments: [(11, 11, 9, 11, 13), (11, 11, 23, 11, 13), (11, 29, 15, 12, 1), (2, 27, 22, 3, 1)])
    func `counts the day the trial started and the two days after it`(
        month: Int,
        day: Int,
        hour: Int,
        lastMonth: Int,
        lastDay: Int,
    ) throws {
        let started = DateComponents(year: 2026, month: month, day: day, hour: hour, minute: 59)
        let start = try #require(Calendar.gmt.date(from: started))
        let expected = try #require(Calendar.gmt.date(from: DateComponents(year: 2026, month: lastMonth, day: lastDay)))

        #expect(ProAccess.trialLastDay(startedOn: start, now: start, calendar: .gmt) == expected)
    }

    @Test(arguments: [(86399.0, ProAccess.Status.trial), (86400, .expired)])
    func `runs the trial through its last day and no longer`(elapsed: TimeInterval, expected: ProAccess.Status) throws {
        let start = try #require(Calendar.gmt.date(from: DateComponents(year: 2026, month: 11, day: 29, hour: 23)))
        let lastDay = ProAccess.trialLastDay(startedOn: start, now: start, calendar: .gmt)

        let now = lastDay.addingTimeInterval(elapsed)

        #expect(ProAccess.trialStatus(startedOn: start, now: now, calendar: .gmt) == expected)
    }

    @Test(arguments: [(2026, 10, 30, 11, 2), (2027, 3, 12, 3, 15)])
    func `ends the trial at midnight when the clocks change during it`(
        year: Int,
        month: Int,
        day: Int,
        endMonth: Int,
        endDay: Int,
    ) throws {
        var calendar = Calendar.gmt
        calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))

        let start = try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 15)))
        let end = try #require(calendar.date(from: DateComponents(year: year, month: endMonth, day: endDay)))

        #expect(ProAccess.trialStatus(startedOn: start, now: end.addingTimeInterval(-1), calendar: calendar) == .trial)
        #expect(ProAccess.trialStatus(startedOn: start, now: end, calendar: calendar) == .expired)
    }

    @Test
    func `ends a trial that starts in the future three days after today`() throws {
        let end = try #require(Calendar.gmt.date(from: DateComponents(year: 2027, month: 1, day: 18)))

        #expect(ProAccess.trialEnd(startedOn: Date.fixed.addingTimeInterval(30 * 86400), now: .fixed, calendar: .gmt) == end)
    }

    @Test(arguments: [(1, ProAccess.Status.trial), (56, .trial), (57, .expired), (-240, .trial)])
    func `runs the trial until the end of its third day`(hoursSinceStart: Int, expected: ProAccess.Status) throws {
        let start = try #require(Calendar.gmt.date(from: DateComponents(year: 2026, month: 10, day: 10, hour: 15)))

        let now = start.addingTimeInterval(Double(hoursSinceStart) * 3600)

        #expect(ProAccess.trialStatus(startedOn: start, now: now, calendar: .gmt) == expected)
    }
}
