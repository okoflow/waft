import Testing
import WaftCore
@testable import WaftFeatures

struct StatisticsModelTests {
    @Test(arguments: [("Hello, world! How are you?", 5), ("Привет, мир! Как дела?", 4)])
    func `records the words of a dictation without punctuation and saves the statistics`(text: String, words: Int) {
        let store = FakeValueStore<DictationStatistics>()
        let statistics = StatisticsModel(store: store)
        statistics.record(text, seconds: 2)

        #expect(statistics.statistics.allTime.words == words)
        #expect(statistics.statistics.allTime.dictations == 1)
        #expect(store.value == statistics.statistics)
    }

    @Test
    func `resets the statistics and removes the store`() {
        let store = FakeValueStore<DictationStatistics>()
        let statistics = StatisticsModel(store: store)
        statistics.record("Hello world", seconds: 2)
        statistics.reset()

        #expect(statistics.statistics == DictationStatistics())
        #expect(store.value == nil)
    }
}
