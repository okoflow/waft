import Testing
import WaftCore
@testable import WaftFeatures

struct TranslatorModelSourceTests {
    private let settings = SettingsModel.inMemory()

    @Test
    func `follows the text over a chosen source when the text is in the target language`() async throws {
        let rewriter = FakeTextRewriter(.success("Привет."))
        let detector = FakeLanguageDetector(languagesByText: ["Hello": .english])
        let translator = TranslatorModel.translating(with: rewriter, settings: settings, detector: detector)

        translator.source = .russian
        translator.input = "Hello"

        #expect(await Poll.until(timeout: .seconds(5)) { translator.output == "Привет." })

        let request = try #require(rewriter.requests.last)

        #expect(request.textTask == .translate(from: nil, into: .russian))
        #expect(translator.knownSource == .english)
        #expect(translator.isShowingDetected)
        #expect(translator.source == .russian)
    }

    @Test
    func `follows the text over a chosen source when it is in the two-way language`() async throws {
        settings.settings.translator.translation = Translation(target: .english, twoWayLanguage: .russian)
        let rewriter = FakeTextRewriter(.success("Hello."))
        let detector = FakeLanguageDetector(languagesByText: ["Привет": .russian])
        let translator = TranslatorModel.translating(with: rewriter, settings: settings, detector: detector)

        translator.source = .german
        translator.input = "Привет"

        #expect(await Poll.until(timeout: .seconds(5)) { translator.output == "Hello." })

        let request = try #require(rewriter.requests.last)

        #expect(request.textTask == .translate(from: nil, into: .english))
        #expect(translator.knownSource == .russian)
    }

    @Test
    func `keeps and remembers a chosen source when the text looks like a language outside the pair`() async throws {
        let rewriter = FakeTextRewriter(.success("Child."))
        let detector = FakeLanguageDetector(languagesByText: ["Kind": .dutch])
        let translator = TranslatorModel.translating(with: rewriter, settings: settings, detector: detector)

        translator.source = .german
        translator.input = "Kind"

        #expect(await Poll.until(timeout: .seconds(5)) { translator.output == "Child." })

        let request = try #require(rewriter.requests.last)

        #expect(request.textTask == .translate(from: .german, into: .english))
        #expect(translator.knownSource == .german)
        #expect(!translator.isShowingDetected)
        #expect(translator.recentLanguages == [.german])
    }
}
