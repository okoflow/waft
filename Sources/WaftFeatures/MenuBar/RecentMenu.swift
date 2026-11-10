import SwiftUI
import WaftCore

struct RecentMenu: View {
    let history: HistoryModel
    let showHistory: () -> Void

    var body: some View {
        Menu("Recent Dictations") {
            let entries = history.recentEntries

            if entries.isEmpty {
                Text("No dictations yet")
            }

            ForEach(entries, id: \.date) { entry in
                Button(entry.preview) { history.copy(entry) }
            }

            Divider()

            Button("Show History", action: showHistory)
        }
    }
}
