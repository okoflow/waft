import WaftCore

final class FakeKeyboardLayout: KeyboardLayout {
    private let characters: [Int64: String]

    init(_ characters: [Int64: String]) {
        self.characters = characters
    }

    func character(forKeyCode keyCode: Int64) -> String? {
        characters[keyCode]
    }
}
