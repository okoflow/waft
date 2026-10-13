import Foundation
import NaturalLanguage
import Observation
import WaftCore

@Observable
final class StatisticsModel {
    private(set) var statistics: DictationStatistics

    private let store: any ValueStore<DictationStatistics>

    init(store: any ValueStore<DictationStatistics>) {
        self.store = store
        statistics = store.read(default: DictationStatistics())
    }

    private static func wordCount(of text: String) -> Int {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        return tokenizer.tokens(for: text.startIndex ..< text.endIndex).count
    }

    func record(_ text: String, seconds: Double) {
        statistics.record(words: Self.wordCount(of: text), seconds: seconds, on: Date())
        store.write(statistics)
    }

    func reset() {
        statistics = DictationStatistics()
        store.remove()
    }
}
