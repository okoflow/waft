import Testing
import WaftCore

struct SpeechModelTests {
    @Test(arguments: [
        (SpeechModel.fast, false, SpeechModel.fast),
        (.fast, true, .fast),
        (.accurate, true, .accurate),
        (.accurate, false, .fast),
    ])
    func `falls back to the fast model when Waft+ is locked`(model: SpeechModel, isUnlocked: Bool, expected: SpeechModel) {
        #expect(model.usable(withProUnlocked: isUnlocked) == expected)
    }
}
