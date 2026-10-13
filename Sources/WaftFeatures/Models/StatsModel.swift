import Foundation
import NaturalLanguage
import Observation
import WaftCore

@Observable
final class StatsModel {
    private(set) var stats: DictationStats

    private let store: any ValueStore<DictationStats>

    init(store: any ValueStore<DictationStats>) {
        self.store = store
        stats = store.read(default: DictationStats())
    }

    private static func wordCount(of text: String) -> Int {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        return tokenizer.tokens(for: text.startIndex ..< text.endIndex).count
    }

    func record(_ text: String, seconds: Double) {
        stats.record(words: Self.wordCount(of: text), seconds: seconds, on: Date())
        store.write(stats)
    }

    func reset() {
        stats = DictationStats()
        store.remove()
    }
}
