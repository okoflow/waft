import Foundation

extension Calendar {
    static let gmt = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt

        return calendar
    }()
}
