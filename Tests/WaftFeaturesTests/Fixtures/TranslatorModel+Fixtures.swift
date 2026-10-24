import WaftCore
@testable import WaftFeatures

extension TranslatorModel {
    static func translating(
        with rewriter: FakeTextRewriter,
        settings: SettingsModel,
        detector: FakeLanguageDetector = FakeLanguageDetector(),
        pro: ProModel = .unlicensed(),
        clipboard: FakeClipboard = FakeClipboard(),
        typingPause: Duration = .zero,
    ) -> TranslatorModel {
        TranslatorModel(
            rewriters: .all(rewriter),
            detector: detector,
            settings: settings,
            pro: pro,
            clipboard: clipboard,
            typingPause: typingPause,
        )
    }
}
