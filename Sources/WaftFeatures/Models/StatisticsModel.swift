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

    @discardableResult
    func record(_ text: String, seconds: Double, replacing previous: DictationRecord? = nil) -> DictationRecord {
        let words = Self.wordCount(of: text)

        guard let previous else {
            let counted = DictationRecord(date: Date(), words: words)

            statistics.record(words: words, seconds: seconds, on: counted.date)
            store.write(statistics)

            return counted
        }

        statistics.replace(words: previous.words, with: words, seconds: seconds, on: previous.date)
        store.write(statistics)

        return DictationRecord(date: previous.date, words: words)
    }

    func reset() {
        statistics = DictationStatistics()
        store.remove()
    }
}
