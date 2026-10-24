import Foundation
import SwiftUI
import Testing
import WaftCore
@testable import WaftFeatures

struct HistorySettingsPaneTests {
    private let settings = SettingsModel.inMemory()

    @Test(arguments: [
        (false, "", true, "No dictations yet"),
        (false, "Friday", false, "Waft keeps no dictations while Keep history is off."),
        (true, "Friday", true, "No matches"),
    ])
    func `explains why it shows no dictations`(hasEntries: Bool, searchText: String, keepsHistory: Bool, text: String) {
        settings.settings.keepsHistory = keepsHistory
        let pane = pane(store: FakeValueStore(history(hasEntries: hasEntries)))
        pane.history.searchText = searchText

        #expect(pane.emptyText == LocalizedStringKey(text))
    }

    @Test
    func `explains that the saved history could not be read even while searching`() {
        let pane = pane(store: FakeValueStore(DictationHistory(), isBroken: true))
        pane.history.searchText = "Friday"

        #expect(pane.emptyText == "Waft couldn't read the saved history and kept a copy of it. Clear History deletes both.")
    }

    private func pane(store: FakeValueStore<DictationHistory>) -> HistorySettingsPane {
        HistorySettingsPane(
            settings: settings,
            history: HistoryModel(store: store, settings: settings, clipboard: FakeClipboard()),
            state: SettingsWindowState(),
        )
    }

    private func history(hasEntries: Bool) -> DictationHistory {
        var history = DictationHistory()

        guard hasEntries else { return history }

        history.add(DictationHistory.Entry(date: .now, text: "See you tomorrow.", mode: .light, app: nil))

        return history
    }
}
