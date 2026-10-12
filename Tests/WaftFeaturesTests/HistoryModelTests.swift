import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct HistoryModelTests {
    private static let start = Date(timeIntervalSince1970: 1_800_000_000)

    @Test
    func `shows fifty entries a page with the newest first`() {
        let page = model(entries: 120).currentPage

        #expect(page.entries.count == 50)
        #expect(page.entries.first?.text == "Entry 120")
        #expect(page.firstPosition == 1)
        #expect(page.lastPosition == 50)
        #expect(page.total == 120)
        #expect(!page.hasPrevious)
        #expect(page.hasNext)
    }

    @Test
    func `stops on the last page`() {
        let history = model(entries: 120)

        for _ in 1 ... 3 {
            history.showNextPage()
        }

        let page = history.currentPage

        #expect(page.entries.first?.text == "Entry 20")
        #expect(page.firstPosition == 101)
        #expect(page.lastPosition == 120)
        #expect(page.hasPrevious)
        #expect(!page.hasNext)
    }

    @Test
    func `goes back from the shown page after the history shrinks`() {
        let settings = settingsModel()
        let history = model(entries: 120, settings: settings)
        history.showNextPage()
        history.showNextPage()
        settings.settings.historyLimit = 100
        history.keepWithinLimits()

        #expect(history.currentPage.firstPosition == 51)

        history.showPreviousPage()

        #expect(history.currentPage.firstPosition == 1)
    }

    @Test
    func `searches from the first page for the trimmed query`() {
        let history = model(entries: 120)
        history.showNextPage()
        history.searchText = "  entry 11\n"
        let page = history.currentPage

        #expect(page.total == 11)
        #expect(page.entries.first?.text == "Entry 119")
        #expect(page.entries.last?.text == "Entry 11")
        #expect(page.firstPosition == 1)
    }

    @Test
    func `shows an empty page without history`() {
        let page = model(entries: 0).currentPage

        #expect(page.entries.isEmpty)
        #expect(page.total == 0)
        #expect(!page.isPaged)
    }

    @Test
    func `keeps nothing while history is off`() {
        let settings = settingsModel()
        let history = model(entries: 0, settings: settings)
        settings.settings.keepsHistory = false
        history.add(entry(1))

        #expect(history.history.entries.isEmpty)
    }

    @Test
    func `copies an entry`() {
        let clipboard = FakeClipboard()
        let history = HistoryModel(store: FakeValueStore(history(entries: 1)), settings: settingsModel(), clipboard: clipboard)
        history.copy(entry(1))

        #expect(clipboard.copied == ["Entry 1"])
    }

    @Test
    func `removes every entry from the store`() {
        let store = FakeValueStore(history(entries: 3))
        let history = HistoryModel(store: store, settings: settingsModel(), clipboard: FakeClipboard())
        history.removeAll()

        #expect(history.history.entries.isEmpty)
        #expect(store.value == nil)
    }

    private func model(entries count: Int) -> HistoryModel {
        model(entries: count, settings: settingsModel())
    }

    private func model(entries count: Int, settings: SettingsModel) -> HistoryModel {
        HistoryModel(store: FakeValueStore(history(entries: count)), settings: settings, clipboard: FakeClipboard())
    }

    private func settingsModel() -> SettingsModel {
        var settings = Settings(languages: .preferred(by: []))
        settings.historyRetention = .forever

        return SettingsModel(store: FakeValueStore(settings), loginItem: FakeLoginItem(), audioInputs: FakeAudioInputProvider())
    }

    private func history(entries count: Int) -> DictationHistory {
        var history = DictationHistory()

        for number in stride(from: 1, through: count, by: 1) {
            history.add(entry(number))
        }

        return history
    }

    private func entry(_ number: Int) -> DictationHistory.Entry {
        DictationHistory.Entry(
            date: Self.start.addingTimeInterval(Double(number)),
            text: "Entry \(number)",
            mode: .light,
            app: nil,
        )
    }
}

private final class FakeClipboard: Clipboard {
    private(set) var copied: [String] = []

    func copy(_ text: String) {
        copied.append(text)
    }
}
