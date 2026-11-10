import Foundation
import SwiftUI
import Testing
import WaftCore
@testable import WaftFeatures

struct HistoryModelEmptyTextTests {
    @Test(arguments: [
        (false, "", true, "No dictations yet"),
        (false, "Friday", false, "Waft keeps no dictations while Keep history is off."),
        (true, "Friday", true, "No matches"),
    ])
    func `explains why it shows no dictations`(hasEntry: Bool, searchText: String, keepsHistory: Bool, text: String) {
        var saved = DictationHistory()

        if hasEntry {
            saved.add(DictationHistory.Entry(date: Date(), text: "Entry 1", mode: .light, app: nil))
        }

        let settings = SettingsModel.inMemory()
        settings.settings.keepsHistory = keepsHistory
        let history = HistoryModel(store: FakeValueStore(saved), settings: settings, clipboard: FakeClipboard())
        history.searchText = searchText

        #expect(history.emptyText == LocalizedStringKey(text))
    }

    @Test
    func `explains that the saved history could not be read even while searching`() {
        let store = FakeValueStore(DictationHistory(), isBroken: true)
        let history = HistoryModel(store: store, settings: .inMemory(), clipboard: FakeClipboard())
        history.searchText = "Friday"

        #expect(history.emptyText == "Waft couldn't read the saved history and kept a copy of it. Clear History deletes both.")
    }
}
