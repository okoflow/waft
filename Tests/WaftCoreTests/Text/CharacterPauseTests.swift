import Testing
@testable import WaftCore

struct CharacterPauseTests {
    @Test(arguments: [".", ",", "?", "…", "。", "、", "，", "،", "؛", "؟", "۔", "।", "॥"] as [Character])
    func `treats the pause marks of every script as pauses`(mark: Character) {
        #expect(mark.isPauseMark)
    }

    @Test(arguments: ["a", " ", "-", "'", "\n"] as [Character])
    func `treats letters, white space, and joining marks as no pause`(character: Character) {
        #expect(!character.isPauseMark)
    }
}
