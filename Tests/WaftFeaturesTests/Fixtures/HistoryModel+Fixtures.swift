import WaftCore
@testable import WaftFeatures

extension HistoryModel {
    static func inMemory() -> HistoryModel {
        HistoryModel(store: FakeValueStore<DictationHistory>(), settings: .inMemory(), clipboard: FakeClipboard())
    }
}
