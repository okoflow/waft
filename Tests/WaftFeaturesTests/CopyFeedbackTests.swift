import Testing
import WaftCore
@testable import WaftFeatures

struct CopyFeedbackTests {
    @Test
    func `shows only the most recently copied item`() {
        let feedback = CopyFeedback<Int>()
        feedback.show(1)
        feedback.show(2)

        #expect(!feedback.isShowing(1))
        #expect(feedback.isShowing(2))
    }

    @Test
    func `stops showing the item after the pause`() async {
        let feedback = CopyFeedback<Int>(pause: .zero)
        feedback.show(1)

        #expect(feedback.isShowing(1))
        #expect(await Poll.until(timeout: .seconds(5)) { !feedback.isShowing(1) })
    }
}
