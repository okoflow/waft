import Foundation
import Testing
import WaftCore

struct TranscriptProcessorWritingSystemTests {
    @Test(arguments: [
        (Language.english, WritingVariant?.none, "see you tomorrow", "Увидимся завтра."),
        (.russian, nil, "увидимся завтра", "See you tomorrow."),
        (.serbian, .cyrillic, "vidimo se sutra", "See you tomorrow."),
    ])
    func `keeps each translation as answered`(spoken: Language, variant: WritingVariant?, text: String, answer: String) async {
        let translation = Translation(target: .english, twoWayLanguage: .russian)
        let setup = RewriteSetup(provider: .cloud(.claude), instructions: "Translate.", translation: translation)
        let reply = Result<String, RewriteError>.success(answer)
        let processed = await process(text, mode: .translate, language: spoken, variant: variant, setup: setup, answer: reply)

        #expect(processed == ProcessedText(text: answer, mode: .translate))
    }

    @Test(arguments: [
        (Language.english, Language.chinese, WritingVariants(), "我們明天開會。", "我们明天开会。"),
        (.english, .chinese, WritingVariants([.chinese: .traditional]), "我们明天开会。", "我們明天開會。"),
        (.english, .serbian, WritingVariants(), "Видимо се сутра.", "Vidimo se sutra."),
        (.english, .serbian, WritingVariants([.serbian: .cyrillic]), "Vidimo se sutra.", "Видимо се сутра."),
        (.serbian, .serbian, WritingVariants([.serbian: .cyrillic]), "Vidimo se sutra.", "Видимо се сутра."),
    ])
    func `writes a translation in the script chosen for the target language`(
        spoken: Language,
        target: Language,
        variants: WritingVariants,
        answer: String,
        expected: String,
    ) async {
        var settings = Settings(languages: .preferred(by: []))
        settings.translation = Translation(target: target)
        settings.writingVariants = variants

        let setup = settings.rewriteSetup(for: .translate)
        let reply = Result<String, RewriteError>.success(answer)
        let variant = variants.variant(for: spoken)
        let processed = await process("hello", mode: .translate, language: spoken, variant: variant, setup: setup, answer: reply)

        #expect(processed == ProcessedText(text: expected, mode: .translate))
    }

    @Test(arguments: [
        (Mode.clean, Result<String, RewriteError>.success("Vidimo se sutra."), Mode.clean, RewriteFallback?.none),
        (.formal, .success("Vidimo se sutra."), .formal, nil),
        (.translate, .failure(.timeout), .light, .timeout),
    ])
    func `writes a cleanup and a translation that falls back to light in the chosen script`(
        mode: Mode,
        answer: Result<String, RewriteError>,
        processedMode: Mode,
        fallback: RewriteFallback?,
    ) async {
        let processed = await process("vidimo se sutra", mode: mode, language: .serbian, variant: .cyrillic, answer: answer)

        #expect(processed == ProcessedText(text: "Видимо се сутра.", mode: processedMode, fallback: fallback))
    }

    @Test(arguments: [
        (Language.serbian, WritingVariant.latin, "Привет, как дела?"),
        (.serbian, .cyrillic, "See you tomorrow."),
        (.serbian, .cyrillic, "Novak Đoković played the match."),
        (.chinese, .simplified, "報告書を忘れないでください。"),
        (.serbian, .latin, "Сутра нећу доћи."),
        (.chinese, .traditional, "我们明天开会。"),
    ])
    func `keeps a custom answer in the script the model wrote`(spoken: Language, variant: WritingVariant, answer: String) async {
        let reply = Result<String, RewriteError>.success(answer)
        let processed = await process("hello", mode: .custom(UUID()), language: spoken, variant: variant, answer: reply)

        #expect(processed.text == answer)
    }

    @Test
    func `writes the text in the chosen script and keeps a snippet as written`() async {
        let vocabulary = Vocabulary(terms: [], snippets: [Vocabulary.Snippet(trigger: "brb", text: "马上回来")])
        let processed = await process("这是测试 brb", mode: .light, language: .chinese, variant: .traditional, vocabulary: vocabulary)

        #expect(processed.text == "這是測試 马上回来。")
    }
}

extension TranscriptProcessorWritingSystemTests {
    private func process(
        _ text: String,
        mode: Mode,
        language: Language,
        variant: WritingVariant?,
        setup: RewriteSetup = RewriteSetup(provider: .cloud(.claude), instructions: "Clean."),
        answer: Result<String, RewriteError> = .success("Unused."),
        vocabulary: Vocabulary = .empty,
    ) async -> ProcessedText {
        let transcript = Transcript.spoken(text, in: language, variant: variant)

        return await TranscriptProcessor.answering(answer, log: RewriteLog())
            .process(transcript, mode: mode, setup: setup, vocabulary: vocabulary, allowsAI: true)
    }
}
