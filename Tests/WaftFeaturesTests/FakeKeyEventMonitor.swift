import WaftCore

final class FakeKeyEventMonitor: KeyEventMonitor {
    let events: AsyncStream<KeyEvent>
    var isRunning = false
    var startsSuccessfully: Bool

    private(set) var startCount = 0

    private let continuation: AsyncStream<KeyEvent>.Continuation

    init(startsSuccessfully: Bool = true) {
        let (events, continuation) = AsyncStream.makeStream(of: KeyEvent.self, bufferingPolicy: .bufferingNewest(0))

        self.events = events
        self.continuation = continuation
        self.startsSuccessfully = startsSuccessfully
    }

    func start() -> Bool {
        startCount += 1
        isRunning = startsSuccessfully

        return startsSuccessfully
    }

    func send(_ event: KeyEvent) async {
        await Poll.until(timeout: .seconds(5), every: .milliseconds(1)) {
            guard case .dropped = continuation.yield(event) else { return true }

            return false
        }
    }
}
