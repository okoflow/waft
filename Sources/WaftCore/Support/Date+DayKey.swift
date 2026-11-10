import Foundation

extension Date {
    func dayKey(in calendar: Calendar) -> String {
        formatted(Date.ISO8601FormatStyle(timeZone: calendar.timeZone).year().month().day())
    }
}
