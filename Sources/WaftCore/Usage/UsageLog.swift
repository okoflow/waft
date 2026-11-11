package import Foundation

package struct UsageLog: Codable, Equatable, Sendable {
    package struct Day: Codable, Equatable, Sendable {
        package fileprivate(set) var counts = UsageCounts()

        fileprivate var isSent = false

        package init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            counts = container.decode(.counts, default: counts)
            isSent = container.decode(.isSent, default: isSent)
        }

        fileprivate init() {}
    }

    private static let keptDays = 7

    package let installation: UUID
    package private(set) var days: [String: Day] = [:]

    package var unsentDays: [String] {
        days.filter { !$0.value.isSent }.keys.sorted()
    }

    package init(installation: UUID) {
        self.installation = installation
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        installation = try container.decode(UUID.self, forKey: .installation)
        days = container.decodeValidValues(.days)
    }

    private static func oldestKey(on date: Date, calendar: Calendar) -> String {
        guard let oldest = calendar.date(byAdding: .day, value: -keptDays, to: date) else { return date.dayKey(in: calendar) }

        return oldest.dayKey(in: calendar)
    }

    private static func keeps(_ day: Day, of key: String, today: String, oldest: String) -> Bool {
        guard key >= oldest else { return false }
        guard key != today else { return true }

        return !day.isSent
    }

    package mutating func startDay(on date: Date, calendar: Calendar = .current) {
        let today = date.dayKey(in: calendar)
        let oldest = Self.oldestKey(on: date, calendar: calendar)

        days = days.filter { Self.keeps($0.value, of: $0.key, today: today, oldest: oldest) }

        if days[today] == nil {
            days[today] = Day()
        }
    }

    package mutating func record(_ event: UsageEvent, on date: Date, calendar: Calendar = .current) {
        let key = date.dayKey(in: calendar)

        var day = days[key, default: Day()]

        day.counts.count(event)
        day.isSent = false

        days[key] = day
    }

    package mutating func markSent(_ key: String, with counts: UsageCounts) {
        guard var day = days[key], day.counts == counts else { return }

        day.isSent = true

        days[key] = day
    }
}
