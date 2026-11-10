import WaftCore
@testable import WaftFeatures

extension DictationQueue {
    static func transcribing(
        with transcriber: FakeTranscriber,
        hud: HUDController,
        rewriter: FakeTextRewriter = FakeTextRewriter(),
        inserter: FakeTextInserter = FakeTextInserter(),
        clipboard: FakeClipboard = FakeClipboard(),
        history: HistoryModel = .inMemory(),
        statistics: StatisticsModel = StatisticsModel(store: FakeValueStore<DictationStatistics>()),
        transcriptLifetime: Duration = .seconds(600),
    ) -> DictationQueue {
        DictationQueue(
            transcriber: transcriber,
            rewriters: .all(rewriter),
            inserter: inserter,
            clipboard: clipboard,
            history: history,
            statistics: statistics,
            hud: hud,
            transcriptLifetime: transcriptLifetime,
        )
    }
}
