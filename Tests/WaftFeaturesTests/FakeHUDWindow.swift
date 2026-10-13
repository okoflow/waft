@testable import WaftFeatures

final class FakeHUDWindow: HUDWindow {
    private(set) var isShown = false

    func showOnActiveScreen() {
        isShown = true
    }

    func orderOut(_: Any?) {
        isShown = false
    }
}
