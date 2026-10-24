import Testing
import WaftCore
@testable import WaftFeatures

struct TranslatorModelSwapTests {
    private let settings = SettingsModel.inMemory()

    @Test
    func `swaps the pair, keeps detecting, and translates the translation back`() async {
        let rewriter = FakeTextRewriter(.success("Hello."))
        let detector = FakeLanguageDetector(languagesByText: ["Привет": .russian, "Hello.": .english])
        let translator = TranslatorModel.translating(with: rewriter, settings: settings, detector: detector)

        translator.input = "Привет"

        #expect(await Poll.until(timeout: .seconds(5)) { translator.output == "Hello." })

        translator.swapLanguages()

        #expect(translator.source == nil)
        #expect(settings.settings.translator.translation == Translation(target: .russian, twoWayLanguage: .english))
        #expect(translator.input == "Hello.")
        #expect(await Poll.until(timeout: .seconds(5)) { rewriter.requests.count == 2 })
        #expect(rewriter.requests.last?.textTask == .translate(from: nil, into: .russian))
    }

    @Test
    func `lets go of a chosen source language and keeps the text typed after the last translation`() async {
        let rewriter = FakeTextRewriter(.success("Hello."))
        let detector = FakeLanguageDetector(language: .russian)
        let translator = TranslatorModel.translating(
            with: rewriter,
            settings: settings,
            detector: detector,
            typingPause: .seconds(60),
        )

        translator.input = "Привет"
        translator.source = .russian

        #expect(await Poll.until(timeout: .seconds(5)) { translator.output == "Hello." })

        translator.input = "Привет, мир"
        translator.swapLanguages()

        #expect(translator.source == nil)
        #expect(translator.input == "Привет, мир")
        #expect(await Poll.until(timeout: .seconds(5)) { rewriter.requests.count == 2 })
        #expect(rewriter.requests.last?.text == "Привет, мир")
        #expect(rewriter.requests.last?.textTask == .translate(from: nil, into: .english))
    }

    @Test
    func `swaps the two-way pair before there is any text`() {
        settings.settings.translator.translation = Translation(target: .english, twoWayLanguage: .russian)
        let rewriter = FakeTextRewriter(.success("Hello."))
        let translator = TranslatorModel.translating(with: rewriter, settings: settings)

        #expect(translator.canSwap)

        translator.swapLanguages()

        #expect(settings.settings.translator.translation == Translation(target: .russian, twoWayLanguage: .english))
        #expect(rewriter.requests.isEmpty)
    }

    @Test
    func `swaps nothing without a known language or a two-way pair`() {
        let rewriter = FakeTextRewriter(.success("Hello."))
        let translator = TranslatorModel.translating(with: rewriter, settings: settings)

        translator.swapLanguages()

        #expect(!translator.canSwap)
        #expect(translator.source == nil)
        #expect(translator.target == .english)
        #expect(rewriter.requests.isEmpty)
    }

    @Test
    func `offers no swap when the text is already in the language it goes into`() async {
        let rewriter = FakeTextRewriter(.success("Hello."))
        let detector = FakeLanguageDetector(language: .english)
        let translator = TranslatorModel.translating(with: rewriter, settings: settings, detector: detector)

        translator.input = "Hello"

        #expect(await Poll.until(timeout: .seconds(5)) { translator.output == "Hello." })
        #expect(!translator.canSwap)
        #expect(!translator.isTwoWay)
    }
}
