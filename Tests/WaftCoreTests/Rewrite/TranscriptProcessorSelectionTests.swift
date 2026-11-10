import Testing
@testable import WaftCore

struct TranscriptProcessorSelectionTests {
    private static let setup = RewriteSetup.fixture(provider: .cloud(.claude), instructions: "Fix the typos.")

    private static let cases = [
        ("    let totl = 1", "let total = 1", "    let total = 1"),
        ("A whole lin.\n", "A whole line.", "A whole line.\n"),
        ("\n\tBoth ends. \n\n", "  Both ends.\n", "\n\tBoth ends. \n\n"),
        ("No edges.", " No edges. ", "No edges."),
    ]

    @Test(arguments: cases)
    func `keeps the white space around an edited selection`(selection: String, answer: String, expected: String) async throws {
        let processor = TranscriptProcessor.answering(.success(answer), log: RewriteLog())

        let edited = try await processor.edit(selection, following: .spoken("fix the typos"), setup: Self.setup)

        #expect(edited == expected)
    }

    @Test(arguments: cases)
    func `keeps the white space around a reworked selection`(selection: String, answer: String, expected: String) async throws {
        let processor = TranscriptProcessor.answering(.success(answer), log: RewriteLog())

        let reworked = try await processor.rework(selection, as: .fix, setup: Self.setup)

        #expect(reworked == expected)
    }

    @Test
    func `keeps the white space around a translation written in another script`() async throws {
        var settings = Settings.defaults
        settings.writingVariants = WritingVariants([.serbian: .cyrillic])

        let task = TextTask.translate(from: nil, into: .serbian)
        let processor = TranscriptProcessor.answering(.success("Vidimo se sutra."), log: RewriteLog())

        let reworked = try await processor.rework(
            "  See you tomorrow.\n",
            as: task,
            setup: settings.translatorSetup(for: .translate),
        )

        #expect(reworked == "  Видимо се сутра.\n")
    }
}
