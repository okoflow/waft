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
        if let license {
            status = .licensed(license)
        } else if Self.isFreeDuringBeta {
            status = .beta
        } else {
            status = Self.trialStatus(startedOn: trialStarted, now: now, calendar: .current)
        }
    }

    package static func trialEnd(startedOn start: Date, now: Date, calendar: Calendar = .current) -> Date {
        let firstDay = calendar.startOfDay(for: min(start, now))
        guard let end = calendar.date(byAdding: .day, value: trialLength, to: firstDay) else { return firstDay }

        return end
    }

    static func trialStatus(startedOn start: Date, now: Date, calendar: Calendar) -> Status {
        now < trialEnd(startedOn: start, now: now, calendar: calendar) ? .trial : .expired
    }
}
