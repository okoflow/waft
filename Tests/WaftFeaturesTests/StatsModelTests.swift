import Testing
import WaftCore
@testable import WaftFeatures

struct StatsModelTests {
    @Test(arguments: [("Hello, world! How are you?", 5), ("Привет, мир! Как дела?", 4)])
    func `records the words of a dictation without punctuation and saves the stats`(text: String, words: Int) {
        let store = FakeValueStore<DictationStats>()
        let stats = StatsModel(store: store)
        stats.record(text, seconds: 2)

        #expect(stats.stats.allTime.words == words)
        #expect(stats.stats.allTime.dictations == 1)
        #expect(store.value == stats.stats)
    }

    @Test
    func `resets the stats and removes the store`() {
        let store = FakeValueStore<DictationStats>()
        let stats = StatsModel(store: store)
        stats.record("Hello world", seconds: 2)
        stats.reset()

        #expect(stats.stats == DictationStats())
        #expect(store.value == nil)
    }
}
