package import Foundation

package struct ProAccess: Equatable, Sendable {
    package enum Status: Equatable, Sendable {
        case licensed(License)
        case beta
        case trial
        case expired
    }

    package static let isFreeDuringBeta = true

    static let trialLength = 3

    package let status: Status

    package var isUnlocked: Bool {
        status != .expired
    }

    package init(license: License?, trialStarted: Date, now: Date) {
        status = Self.status(license: license, trialStarted: trialStarted, now: now)
    }

    package static func trialEnd(startedOn start: Date, now: Date, calendar: Calendar = .current) -> Date {
        let firstDay = calendar.startOfDay(for: min(start, now))
        guard let end = calendar.date(byAdding: .day, value: trialLength, to: firstDay) else { return firstDay }

        return end
    }

    static func trialStatus(startedOn start: Date, now: Date, calendar: Calendar) -> Status {
        now < trialEnd(startedOn: start, now: now, calendar: calendar) ? .trial : .expired
    }

    private static func status(license: License?, trialStarted: Date, now: Date) -> Status {
        if let license {
            return .licensed(license)
        }

        guard !isFreeDuringBeta else { return .beta }

        return trialStatus(startedOn: trialStarted, now: now, calendar: .current)
    }
}
