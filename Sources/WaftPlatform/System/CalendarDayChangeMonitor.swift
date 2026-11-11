package import WaftCore
import Foundation

@MainActor
package final class CalendarDayChangeMonitor: DayChangeMonitor {
    package let dayChanges: AsyncStream<Void>

    private let observer: any NSObjectProtocol

    package init() {
        let (dayChanges, continuation) = AsyncStream.makeStream(of: Void.self)

        self.dayChanges = dayChanges

        observer = NotificationCenter.default.addObserver(forName: .NSCalendarDayChanged, object: nil, queue: nil) { _ in
            continuation.yield()
        }
    }

    isolated deinit {
        NotificationCenter.default.removeObserver(observer)
    }
}
