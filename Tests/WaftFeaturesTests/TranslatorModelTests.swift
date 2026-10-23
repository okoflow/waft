import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct TranslatorModelTests {
    private let settings = SettingsModel.inMemory()
    private let clipboard = FakeClipboard()

    @Test
    func `translates the text after a pause in typing into the chosen language`() async throws {
        let rewriter = FakeTextRewriter(.success("Hello."))
        let translator = model(rewriter, detects: .russian)

        translator.input = "Привет"

        #expect(await Poll.until(timeout: .seconds(5)) { translator.output == "Hello." })

        let request = try #require(rewriter.requests.first)

        #expect(rewriter.requests.count == 1)
        #expect(request.text == "Привет")
        #expect(request.textTask == .translate(from: nil, into: .english))
        #expect(translator.detected == .russian)
        #expect(!translator.isTranslating)
    }

    @Test
    func `translates two-way into the other language when the text is in the target language`() async throws {
        settings.settings.translator.translation = Translation(target: .english, twoWayLanguage: .russian)
        let rewriter = FakeTextRewriter(.success("Привет."))
        let translator = model(rewriter, detects: .english)

        translator.input = "Hello"

        #expect(await Poll.until(timeout: .seconds(5)) { translator.output == "Привет." })

        let request = try #require(rewriter.requests.first)

        #expect(request.textTask == .translate(from: nil, into: .russian))
        #expect(translator.effectiveTarget == .russian)
        #expect(translator.isTwoWay)
    }

    @Test
    func `names a chosen source language to the model and remembers it`() async throws {
        let rewriter = FakeTextRewriter(.success("Hello."))
        let translator = model(rewriter, detects: .dutch)

        translator.source = .german
        translator.input = "Hallo"

        #expect(await Poll.until(timeout: .seconds(5)) { translator.output == "Hello." })

        let request = try #require(rewriter.requests.last)

        #expect(request.textTask == .translate(from: .german, into: .english))
        #expect(!translator.isShowingDetected)
        #expect(translator.recentLanguages == [.german])
    }

    @Test
    func `translates by the instructions and the model of the translator`() async throws {
        settings.settings.translator.instructions.set("Translate like a pirate.", for: .translate)
        settings.settings.translator.cloudModel = .smartest
        let rewriter = FakeTextRewriter(.success("Ahoy."))
        let translator = model(rewriter, detects: .russian)

        translator.input = "Привет"

        #expect(await Poll.until(timeout: .seconds(5)) { translator.output == "Ahoy." })

        let request = try #require(rewriter.requests.first)

        #expect(request.textInstructions == "Translate like a pirate.")
        #expect(request.cloudModel == .smartest)
    }

    @Test
    func `says why a translation failed`() async {
        let translator = model(FakeTextRewriter(.failure(.timeout)), detects: .russian)

        translator.input = "Привет"

        #expect(await Poll.until(timeout: .seconds(5)) { translator.failure == "Claude didn't answer in time" })
        #expect(translator.output.isEmpty)
        #expect(!translator.isTranslating)
    }

    @Test
    func `clears the translation with the text without asking the model`() async {
        let rewriter = FakeTextRewriter(.success("Hello."))
        let translator = model(rewriter, detects: .russian)

        translator.input = "Привет"

        #expect(await Poll.until(timeout: .seconds(5)) { translator.output == "Hello." })

        translator.clear()

        #expect(translator.output.isEmpty)
        #expect(translator.detected == nil)
        #expect(rewriter.requests.count == 1)
    }

    @Test
    func `cuts the text at the character limit and translates the rest`() async throws {
        let rewriter = FakeTextRewriter(.success("Hello."))
        let translator = model(rewriter, detects: .russian)

        translator.input = String(repeating: "a", count: TranslatorModel.characterLimit + 10)

        #expect(translator.input.count == TranslatorModel.characterLimit)
        #expect(await Poll.until(timeout: .seconds(5)) { translator.output == "Hello." })

        let request = try #require(rewriter.requests.first)

        #expect(request.text.count == TranslatorModel.characterLimit)
    }

    @Test
    func `copies the translation or the part of it that was selected`() async {
        let translator = model(FakeTextRewriter(.success("Hello there.")), detects: .russian)

        translator.input = "Привет"

        #expect(await Poll.until(timeout: .seconds(5)) { translator.output == "Hello there." })

        translator.copy("Hello there.")
        translator.copy("there")

        #expect(clipboard.copied == ["Hello there.", "there"])
        #expect(translator.copyFeedback.isShowing("Hello there."))
    }

    @Test(arguments: ["", " \n"])
    func `ignores a blank selection when copying`(selection: String) async {
        let translator = model(FakeTextRewriter(.success("Hello there.")), detects: .russian)

        translator.input = "Привет"

        #expect(await Poll.until(timeout: .seconds(5)) { translator.output == "Hello there." })

        translator.copy(selection)

        #expect(clipboard.copied.isEmpty)
        #expect(!translator.copyFeedback.isShowing("Hello there."))
    }

    @Test
    func `drops a running translation when it stops`() async {
        let rewriter = FakeTextRewriter(.success("Hello."), holdsRequests: true)
        let translator = model(rewriter, detects: .russian)

        translator.input = "Привет"

        #expect(await Poll.until(timeout: .seconds(5)) { translator.isTranslating })

        translator.stop()
        rewriter.release()

        let translated = await Poll.until(timeout: .milliseconds(300)) { !translator.output.isEmpty }

        #expect(!translated)
        #expect(!translator.isTranslating)
    }

    @Test
    func `translates the text again on resuming after a dropped translation`() async {
        let rewriter = FakeTextRewriter(.success("Hello."), holdsRequests: true)
        let translator = model(rewriter, detects: .russian)

        translator.input = "Привет"

        #expect(await Poll.until(timeout: .seconds(5)) { translator.isTranslating })

        translator.stop()
        rewriter.release()
        translator.resume()

        #expect(await Poll.until(timeout: .seconds(5)) { translator.output == "Hello." })
        #expect(rewriter.requests.count == 2)
    }

    @Test
    func `asks the model nothing on resuming after a finished translation`() async {
        let rewriter = FakeTextRewriter(.success("Hello."))
        let translator = model(rewriter, detects: .russian)

        translator.input = "Привет"

        #expect(await Poll.until(timeout: .seconds(5)) { translator.output == "Hello." })

        translator.stop()
        translator.resume()

        #expect(!translator.isTranslating)
        #expect(rewriter.requests.count == 1)
    }

    @Test(.enabled(if: !ProAccess.isFreeDuringBeta))
    func `translates nothing without Waft+`() async {
        let rewriter = FakeTextRewriter(.success("Hello."))
        let translator = model(rewriter, detects: .russian, pro: .unlicensed(trialStarted: .distantPast))

        translator.input = "Привет"

        let translated = await Poll.until(timeout: .milliseconds(800)) { !rewriter.requests.isEmpty }

        #expect(!translated)
        #expect(translator.isLocked)
    }
}

extension TranslatorModelTests {
    private func model(
        _ rewriter: FakeTextRewriter,
        detects language: Language? = nil,
        pro: ProModel = .unlicensed(),
        typingPause: Duration = .zero,
    ) -> TranslatorModel {
        .translating(
            with: rewriter,
            settings: settings,
            detector: FakeLanguageDetector(language: language),
            pro: pro,
            clipboard: clipboard,
            typingPause: typingPause,
        )
    }
}
