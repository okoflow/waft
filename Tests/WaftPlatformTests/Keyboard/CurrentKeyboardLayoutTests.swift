import Testing
import WaftPlatform

struct CurrentKeyboardLayoutTests {
    @Test
    @MainActor
    func `types one character for a letter key`() throws {
        let text = try #require(CurrentKeyboardLayout().character(forKeyCode: 0))
        let character = try #require(text.first)

        #expect(text.count == 1)
        #expect(character.isLetter)
    }
}
