import WaftCore

final class FakeLoginItem: LoginItem {
    private(set) var isEnabled = false

    func setEnabled(_ isEnabled: Bool) {
        self.isEnabled = isEnabled
    }
}
