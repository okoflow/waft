import Observation
import WaftCore

@Observable
final class CopyFeedback<Item: Equatable> {
    private var item: Item?

    @ObservationIgnored private var reset: Task<Void, Never>?

    func show(_ item: Item) {
        self.item = item

        reset?.cancel()
        reset = Task { [weak self] in
            guard await Task.slept(for: .seconds(1.6)) else { return }

            self?.item = nil
        }
    }

    func isShowing(_ item: Item) -> Bool {
        self.item == item
    }
}
