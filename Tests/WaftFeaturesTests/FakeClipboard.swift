import WaftCore

final class FakeClipboard: Clipboard {
    private(set) var copied: [String] = []

    func copy(_ text: String) {
        copied.append(text)
    }
}
