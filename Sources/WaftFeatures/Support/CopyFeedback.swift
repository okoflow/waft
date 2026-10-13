import Observation
import WaftCore

@Observable
final class CopyFeedback<Item: Equatable> {
    private var item: Item?

    @ObservationIgnored private var reset: Task<Void, Never>?

    private let pause: Duration

    init(pause: Duration = .seconds(1.6)) {
        self.pause = pause
    }

    func show(_ item: Item) {
        self.item = item

        reset?.cancel()
        reset = Task { [weak self, pause] in
            guard await Task.slept(for: pause) else { return }

            self?.item = nil
        }
    }

    func isShowing(_ item: Item) -> Bool {
        self.item == item
    }
}
