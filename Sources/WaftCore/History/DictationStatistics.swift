package import Foundation

package struct DictationStatistics: Codable, Equatable, Sendable {
    package struct Day: Codable, Equatable, Sendable {
        private static let typingWordsPerMinute = 40.0

        package var words = 0
        package var dictations = 0
        package var seconds = 0.0

        package var savedOverTyping: Duration {
            .seconds(max(0, Double(words) / Self.typingWordsPerMinute * 60 - seconds))
        }

        package var wordsPerMinute: Int? {
            guard seconds > 0 else { return nil }

            return Int((Double(words) / (seconds / 60)).rounded())
        }

        package init() {}

        fileprivate static func + (left: Day, right: Day) -> Day {
            var sum = left

            sum.words += right.words
            sum.dictations += right.dictations
            sum.seconds += right.seconds

            return sum
        }
    }

    package private(set) var days: [String: Day] = [:]

    package var allTime: Day {
        days.values.reduce(Day(), +)
    }

    package init() {}

    private static func key(for date: Date, calendar: Calendar) -> String {
        date.formatted(Date.ISO8601FormatStyle(timeZone: calendar.timeZone).year().month().day())
    }

    package mutating func record(words: Int, seconds: Double, on date: Date, calendar: Calendar = .current) {
        let key = Self.key(for: date, calendar: calendar)

        var day = days[key, default: Day()]

        day.words += words
        day.dictations += 1
        day.seconds += seconds

        days[key] = day
    }

    package func daily(last count: Int, endingOn date: Date, calendar: Calendar = .current) -> [(date: Date, day: Day)] {
        let end = calendar.startOfDay(for: date)

        return (0 ..< count).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: end)
                .map { ($0, days[Self.key(for: $0, calendar: calendar), default: Day()]) }
        }
    }

    package func total(last count: Int, endingOn date: Date, calendar: Calendar = .current) -> Day {
        daily(last: count, endingOn: date, calendar: calendar).map(\.day).reduce(Day(), +)
    }

    package func streak(endingOn date: Date, calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: date)

        var day = streakEnd(onOrBefore: today, calendar: calendar)
        var count = 0

        while let current = day, hasDictated(on: current, calendar: calendar) {
            count += 1
            day = calendar.date(byAdding: .day, value: -1, to: current)
        }

        return count
    }

    private func streakEnd(onOrBefore today: Date, calendar: Calendar) -> Date? {
        guard !hasDictated(on: today, calendar: calendar) else { return today }

        return calendar.date(byAdding: .day, value: -1, to: today)
    }

    private func hasDictated(on date: Date, calendar: Calendar) -> Bool {
        days[Self.key(for: date, calendar: calendar), default: Day()].dictations > 0
    }
}
