import WaftCore
@testable import WaftFeatures

extension TryoutModel {
    static func trying(
        with rewriter: FakeTextRewriter,
        settings: SettingsModel,
        detector: FakeLanguageDetector = FakeLanguageDetector(),
        pro: ProModel = .unlicensed(),
        defaultSample: String = "Sample",
    ) -> TryoutModel {
        TryoutModel(
            rewriters: .all(rewriter),
            detector: detector,
            settings: settings,
            pro: pro,
            defaultSample: defaultSample,
        )
    }
}
