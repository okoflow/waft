import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct TryoutModelTests {
    private nonisolated static let defaultSample = "um so I think we should uh meet on Friday"

    private let settings = SettingsModel.inMemory()

    @Test
    func `runs the sample through a custom mode with its instructions`() async throws {
        settings.settings.customModes = [.emailReply]
        let rewriter = FakeTextRewriter(.success("So I think we should meet on Friday."))
        let tryout = model(rewriter)
        tryout.run(.custom(CustomMode.emailReply.id))

        #expect(await Poll.until(timeout: .seconds(5)) {
            tryout.phase == .finished(text: "So I think we should meet on Friday.", note: nil)
        })

        let request = try #require(rewriter.requests.first)

        #expect(RewritePrompt.system(for: request).contains("<instructions>\nReply as a short email.\n</instructions>"))
    }

    @Test(arguments: [
        (Language?.some(.russian), Language?.none, Language.russian),
        (.german, nil, .english),
        (nil, nil, .english),
        (.english, .russian, .russian),
    ])
    func `runs the sample in the language it is written in among the chosen ones`(
        detected: Language?,
        pinned: Language?,
        expected: Language,
    ) async throws {
        settings.settings.languages = LanguageSelection.preferred(by: ["ru", "en"]).pinning(pinned)
        let rewriter = FakeTextRewriter(.success("Hello."))
        let tryout = model(rewriter, detects: detected)
        tryout.run(.clean)

        #expect(await Poll.until(timeout: .seconds(5)) { !rewriter.requests.isEmpty })

        let request = try #require(rewriter.requests.first)

        #expect(request.language == expected)
    }

    @Test(arguments: ["", " \n"])
    func `ignores a blank sample`(sample: String) {
        let rewriter = FakeTextRewriter(.success("Hello."))
        let tryout = model(rewriter)
        tryout.sample = sample
        tryout.run(.clean)
        tryout.run(task: .fix)

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
            tryout.phase == .finished(
                text: "See you tomorrow.",
                note: RewriteFallback.needsPro.message(for: settings.settings.modelProvider),
            )
        })
        #expect(rewriter.requests.isEmpty)
    }

    @Test
    func `translates the sample by the instructions of the translator`() async throws {
        settings.settings.translator.instructions.set("Translate like a pirate.", for: .translate)
        let rewriter = FakeTextRewriter(.success("Ahoy, matey."))
        let tryout = model(rewriter, detects: .english)
        tryout.sample = "Hello, friend."
        tryout.run(task: .translate)

        #expect(await Poll.until(timeout: .seconds(5)) { tryout.phase == .finished(text: "Ahoy, matey.", note: nil) })

        let request = try #require(rewriter.requests.first)

        #expect(request.textTask == .translate(from: nil, into: .english))
        #expect(request.textInstructions == "Translate like a pirate.")
    }

    @Test
    func `notes why the model could not rework the sample`() async {
        let tryout = model(FakeTextRewriter(.failure(.timeout)))
        tryout.run(task: .fix)

        #expect(await Poll.until(timeout: .seconds(5)) {
            tryout.phase == .finished(text: "", note: "Claude didn't answer in time")
        })
    }

    @Test(.enabled(if: !ProAccess.isFreeDuringBeta))
    func `does not rework the sample without Pro`() {
        let rewriter = FakeTextRewriter(.success("Hello."))
        let tryout = model(rewriter, pro: .unlicensed(trialStarted: .distantPast))
        tryout.run(task: .translate)

        #expect(tryout.phase == .finished(text: "", note: "Translating and fixing text is part of Waft+."))
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

    private func model(
        _ rewriter: FakeTextRewriter,
        detects language: Language? = nil,
        pro: ProModel = .unlicensed(),
    ) -> TryoutModel {
        TryoutModel(
            rewriters: .all(rewriter),
            detector: FakeLanguageDetector(language: language),
            settings: settings,
            pro: pro,
            defaultSample: Self.defaultSample,
        )
    }
}
