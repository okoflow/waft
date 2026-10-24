import SwiftUI
import WaftCore

extension HistoryModel {
    var emptyText: LocalizedStringKey {
        guard history.entries.isEmpty else { return "No matches" }
        guard !hasUnreadableHistory else {
            return "Waft couldn't read the saved history and kept a copy of it. Clear History deletes both."
        }
        guard settings.settings.keepsHistory else { return "Waft keeps no dictations while Keep history is off." }

        return "No dictations yet"
    }
}
