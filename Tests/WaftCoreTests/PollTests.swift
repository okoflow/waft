import Testing
import WaftCore

struct PollTests {
    @Test
    func `succeeds at once when the condition already holds`() async {
        #expect(await Poll.until(timeout: .zero) { true })
    }

    @Test
    func `succeeds once the condition starts to hold`() async {
        var checks = 0

        let succeeded = await Poll.until(timeout: .seconds(5), every: .milliseconds(1)) {
            checks += 1

            return checks == 3
        }

        #expect(succeeded)
        #expect(checks == 3)
    }

    @Test
    func `gives up after the timeout`() async {
        #expect(await !Poll.until(timeout: .milliseconds(30), every: .milliseconds(5)) { false })
    }
}
