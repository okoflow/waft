import Testing
import WaftCore

struct ModeTests {
    @Test
    func `cycles through every mode`() {
        #expect(Mode.allCases.map { $0.next(includingAI: true) } == [.light, .clean, .formal, .translate, .raw])
    }

    @Test
    func `skips the AI modes without Pro`() {
        #expect(Mode.allCases.map { $0.next(includingAI: false) } == [.light, .raw, .light, .light, .light])
    }
}
