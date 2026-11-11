import Testing
@testable import WaftCore

struct RewriteDeadlineTests {
    @Test
    func `returns an answer that arrives in time`() async throws {
        let answer = try await RewriteDeadline.run(.seconds(5)) { "Fast." }

        #expect(answer == "Fast.")
    }

    @Test
    func `times out a slow rewrite without waiting for it`() async {
        let clock = ContinuousClock()

        let start = clock.now

        await #expect(throws: RewriteError.timeout) {
            try await RewriteDeadline.run(.zero) { () async throws(RewriteError) -> String in
                do {
                    try await Task.sleep(for: .seconds(10))
                } catch {
                    throw .offline
                }

                return "Late."
            }
        }

        #expect(clock.now - start < .seconds(5))
    }

    @Test
    func `passes on the error of the rewrite`() async {
        await #expect(throws: RewriteError.refused) {
            try await RewriteDeadline.run(.seconds(5)) { () async throws(RewriteError) -> String in
                throw .refused
            }
        }
    }
}
