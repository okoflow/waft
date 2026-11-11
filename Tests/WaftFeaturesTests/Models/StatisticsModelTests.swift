import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct StatisticsModelTests {
    private static var saved: DictationStatistics {
        var statistics = DictationStatistics()
        statistics.record(words: 12, seconds: 6, on: Date(timeIntervalSince1970: 1_800_000_000))

        return statistics
    }

    @Test
    func `loads the saved statistics`() {
        #expect(StatisticsModel(store: FakeValueStore(Self.saved)).statistics == Self.saved)
    }

    @Test
    func `starts from zero when the saved statistics are unreadable and saves over them with the next dictation`() {
        let store = FakeValueStore(Self.saved, isBroken: true)
        let statistics = StatisticsModel(store: store)

        #expect(statistics.statistics == DictationStatistics())

        statistics.record("Hello world", seconds: 2)

        #expect(statistics.statistics.allTime.dictations == 1)
        #expect(store.value == statistics.statistics)
    }

    @Test
    func `keeps counting in memory when the statistics cannot be saved`() {
        let store = FakeValueStore(Self.saved, failsSaving: true)
        let statistics = StatisticsModel(store: store)

        statistics.record("Hello world", seconds: 2)

        #expect(statistics.statistics.allTime.dictations == Self.saved.allTime.dictations + 1)
        #expect(store.value == Self.saved)
    }

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
    func `counts a dictation once when its text replaces what it recorded before and saves the statistics`() {
        let store = FakeValueStore<DictationStatistics>()
        let statistics = StatisticsModel(store: store)
        let part = statistics.record("Hello", seconds: 2)

        let whole = statistics.record("Hello world", seconds: 2, replacing: part)

        #expect(whole.date == part.date)
        #expect(whole.words == 2)
        #expect(statistics.statistics.allTime.words == 2)
        #expect(statistics.statistics.allTime.dictations == 1)
        #expect(statistics.statistics.allTime.seconds == 2)
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

    @Test
    func `shows zero after a reset that could not remove the saved statistics`() {
        let store = FakeValueStore(Self.saved, failsDeleting: true)
        let statistics = StatisticsModel(store: store)

        statistics.reset()

        #expect(statistics.statistics == DictationStatistics())
        #expect(store.value == Self.saved)
    }
}
