import Foundation
import Observation
import WaftCore

@Observable
final class HistoryModel {
    struct Page {
        let entries: [DictationHistory.Entry]
        let firstPosition: Int
        let total: Int
        let hasPrevious: Bool
        let hasNext: Bool

        var lastPosition: Int {
            firstPosition + entries.count - 1
        }

        var isPaged: Bool {
            hasPrevious || hasNext
        }
    }

    private static let pageSize = 50
    private static let recentCount = 5

    private(set) var history: DictationHistory
    private(set) var hasUnreadableHistory = false

    var searchText = "" {
        didSet { pageIndex = 0 }
    }

    private var pageIndex = 0

    @ObservationIgnored private var expiry: Task<Void, Never>?

    private let store: any ValueStore<DictationHistory>
    private let settings: SettingsModel
    private let clipboard: any Clipboard

    var currentPage: Page {
        let matching = matchingEntries
        let lastIndex = Self.lastPageIndex(forCount: matching.count)
        let index = min(pageIndex, lastIndex)
        let entries = Array(matching.dropFirst(index * Self.pageSize).prefix(Self.pageSize))

        return Page(
            entries: entries,
            firstPosition: index * Self.pageSize + 1,
            total: matching.count,
            hasPrevious: index > 0,
            hasNext: index < lastIndex,
        )
    }

    var recentEntries: [DictationHistory.Entry] {
        Array(history.newestFirst.prefix(Self.recentCount))
    }

    private var matchingEntries: [DictationHistory.Entry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return history.newestFirst }

        return history.newestFirst.filter { $0.text.localizedCaseInsensitiveContains(query) }
    }

    init(store: any ValueStore<DictationHistory>, settings: SettingsModel, clipboard: any Clipboard) {
        self.store = store
        self.settings = settings
        self.clipboard = clipboard

        if let savedHistory = store.read() {
            history = savedHistory
        } else {
            history = DictationHistory()
            hasUnreadableHistory = store.exists()
        }

        keepWithinLimits()
    }

    private static func lastPageIndex(forCount count: Int) -> Int {
        max(0, (count - 1) / pageSize)
    }

    func showPreviousPage() {
        let shown = min(pageIndex, Self.lastPageIndex(forCount: matchingEntries.count))

        pageIndex = max(0, shown - 1)
    }

    func showNextPage() {
        guard currentPage.hasNext else { return }

        pageIndex += 1
    }

    func copy(_ entry: DictationHistory.Entry) {
        clipboard.copy(entry.text)
    }

    func removeAll() {
        guard store.remove() else { return }

        hasUnreadableHistory = false
        history.removeAll()
        pageIndex = 0
    }

    func add(_ entry: DictationHistory.Entry) {
        guard settings.settings.keepsHistory else { return }

        history.add(entry)
        prune(at: entry.date)
        store.write(history)
    }

    func expireOldEntries(every interval: Duration = .seconds(3600)) {
        expiry?.cancel()
        expiry = Task { [weak self] in
            while await Task.slept(for: interval) {
                guard let self else { return }

                keepWithinLimits()
            }
        }
    }

    func keepWithinLimits() {
        let count = history.entries.count

        prune(at: Date())

        guard history.entries.count != count else { return }

        store.write(history)
    }

    private func prune(at now: Date) {
        history.prune(keeping: settings.settings.historyRetention, limit: settings.settings.historyLimit, now: now)
    }
}
