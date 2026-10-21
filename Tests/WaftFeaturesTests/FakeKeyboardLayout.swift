import WaftCore

final class FakeKeyboardLayout: KeyboardLayout {
    private let characters: [Int64: String]

    init(_ characters: [Int64: String] = [3: "f", 17: "t", 40: "k", 46: "m"]) {
        self.characters = characters
    }

    func character(forKeyCode keyCode: Int64) -> String? {
        characters[keyCode]
    }
}
