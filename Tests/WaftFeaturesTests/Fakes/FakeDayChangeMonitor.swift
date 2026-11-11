import WaftCore

final class FakeDayChangeMonitor: DayChangeMonitor {
    let dayChanges: AsyncStream<Void>

    private let continuation: AsyncStream<Void>.Continuation

    init() {
        (dayChanges, continuation) = AsyncStream.makeStream(of: Void.self)
    }

    func changeDay() {
        continuation.yield()
    }
}
