import Testing
import WaftCore
@testable import WaftFeatures

struct ShortcutActionDisplayTests {
    @Test(arguments: [
        (ShortcutConflict.shortcut(.translator), "Open the translator"),
        (.key(.dictation), "Dictation key"),
        (.key(.edit), "Editing key"),
    ])
    func `names a conflict after the shortcut or the key that holds the combination`(conflict: ShortcutConflict, title: String) {
        #expect(conflict.title == title)
    }
}
