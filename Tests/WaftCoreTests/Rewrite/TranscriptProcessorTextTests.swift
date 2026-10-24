import Foundation
import Testing
@testable import WaftCore

struct TranscriptProcessorTextTests {
    @Test
    func `reworks text with the edit time limit and the instructions of the setup`() async throws {
        let log = RewriteLog()
        let setup = RewriteSetup(provider: .cloud(.claude), instructions: "Fix only the typos.")

        let processor = TranscriptProcessor.answering(.success("We meet on Friday."), log: log)

        let fixed = try await processor.rework("we meat on friday", in: .english, as: .fix, setup: setup)
        let request = try #require(await log.requests.first)

        #expect(fixed == "We meet on Friday.")
        #expect(request.deadline == .seconds(30))
        #expect(RewritePrompt.system(for: request).hasPrefix("Fix only the typos.\n"))
    }

    @Test(arguments: [
        (TextTask.translate(from: nil, into: .serbian), "Vidimo se sutra.", "Видимо се сутра."),
        (.translate(from: nil, into: .chinese), "我們明天開會。", "我们明天开会。"),
        (.fix, "Vidimo se sutra.", "Vidimo se sutra."),
    ])
    func `writes a translation in the script chosen for its target`(
        task: TextTask,
        answer: String,
        expected: String,
    ) async throws {
        var settings = Settings.defaults
        settings.writingVariants = WritingVariants([.serbian: .cyrillic])
        let processor = TranscriptProcessor.answering(.success(answer), log: RewriteLog())

        let reworked = try await processor.rework(
            "see you tomorrow",
            in: .english,
            as: task,
            setup: settings.translatorSetup(for: task.kind),
        )

        #expect(reworked == expected)
    }

    @Test
    func `throws the model failure`() async {
        let processor = TranscriptProcessor.answering(.failure(.timeout), log: RewriteLog())
        let setup = RewriteSetup(provider: .cloud(.claude), instructions: "Unused.")

        await #expect(throws: RewriteError.timeout) {
            try await processor.rework("hi", in: .english, as: .fix, setup: setup)
        }
    }
}
