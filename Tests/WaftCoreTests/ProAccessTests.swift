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

    @Test(.enabled(if: ProAccess.isFreeDuringBeta))
    func `unlocks everything during the beta`() {
        let access = ProAccess(license: nil, trialStarted: .distantPast, now: .now)

        #expect(access.status == .beta)
        #expect(access.isUnlocked)
    }

    @Test(
        .disabled(if: ProAccess.isFreeDuringBeta),
        arguments: [(3600.0, ProAccess.Status.trial, true), (4 * 86400, .expired, false)],
    )
    func `runs a trial without a license once the beta ends`(elapsed: TimeInterval, status: ProAccess.Status, isUnlocked: Bool) {
        let access = ProAccess(license: nil, trialStarted: .fixed, now: Date.fixed.addingTimeInterval(elapsed))

        #expect(access.status == status)
        #expect(access.isUnlocked == isUnlocked)
    }

    @Test(arguments: [(9, 0), (10, 15), (10, 23)])
    func `ends the trial three days after the day it started`(day: Int, hour: Int) throws {
        let start = try #require(Calendar.gmt.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour)))
        let end = try #require(Calendar.gmt.date(from: DateComponents(year: 2026, month: 10, day: day + ProAccess.trialLength)))

        #expect(ProAccess.trialEnd(startedOn: start, now: start, calendar: .gmt) == end)
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
