import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct ModeTryoutModelTests {
    private nonisolated static let defaultSample = "um so I think we should uh meet on Friday"

    private let settings = SettingsModel.inMemory()

    @Test
    func `runs the sample through a custom mode with its instructions`() async throws {
        settings.settings.customModes = [.emailReply]
        let rewriter = FakeTextRewriter(.success("So I think we should meet on Friday."))
        let tryout = model(rewriter)
        tryout.run(.custom(CustomMode.emailReply.id))

        #expect(await Poll.until(timeout: .seconds(5)) {
            tryout.phase == .finished(ProcessedText(
                text: "So I think we should meet on Friday.",
                mode: .custom(CustomMode.emailReply.id),
            ))
        })

        let request = try #require(rewriter.requests.first)

        #expect(RewritePrompt.system(for: request).contains("<instructions>\nReply as a short email.\n</instructions>"))
    }

    @Test(arguments: ["", " \n"])
    func `ignores a blank sample`(sample: String) {
        let rewriter = FakeTextRewriter(.success("Hello."))
        let tryout = model(rewriter)
        tryout.sample = sample
        tryout.run(.clean)

        #expect(tryout.phase == .idle)
        #expect(rewriter.requests.isEmpty)
    }

    @Test(.enabled(if: !ProAccess.isFreeDuringBeta))
    func `falls back to Light without Pro`() async {
        let rewriter = FakeTextRewriter(.success("Hello."))
        let tryout = model(rewriter, pro: .unlicensed(trialStarted: .distantPast))
        tryout.sample = "see you tomorrow"
        tryout.run(.clean)

        #expect(await Poll.until(timeout: .seconds(5)) {
            tryout.phase == .finished(ProcessedText(text: "See you tomorrow.", mode: .light, fallback: .needsPro))
        })
        #expect(rewriter.requests.isEmpty)
    }

    @Test(arguments: [("", defaultSample), ("  ", defaultSample), ("Ship it on Monday", "Ship it on Monday")])
    func `restores the sample on reset only when it is blank`(sample: String, expected: String) {
        let tryout = model(FakeTextRewriter())
        tryout.sample = sample
        tryout.reset()

        #expect(tryout.sample == expected)
        #expect(tryout.phase == .idle)
    }

    @Test
    func `drops a running tryout on reset`() async {
        let rewriter = FakeTextRewriter(.success("So I think we should meet on Friday."), holdsRequests: true)
        let tryout = model(rewriter)
        tryout.run(.clean)

        #expect(tryout.phase == .running)
        #expect(await Poll.until(timeout: .seconds(5)) { !rewriter.requests.isEmpty })

        tryout.reset()
        rewriter.release()
        let finished = await Poll.until(timeout: .milliseconds(300)) { tryout.phase != .idle }

        #expect(!finished)
    }

    private func model(_ rewriter: FakeTextRewriter, pro: ProModel = .unlicensed()) -> ModeTryoutModel {
        ModeTryoutModel(rewriters: .all(rewriter), settings: settings, pro: pro)
    }
}
