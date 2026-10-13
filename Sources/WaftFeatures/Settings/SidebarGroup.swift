import SwiftUI

struct SidebarGroup {
    static let all = [
        SidebarGroup(title: nil, panes: [.overview, .history, .dictionary]),
        SidebarGroup(title: "Settings", panes: [.general, .dictation, .writing, .aiModels]),
    ]

    let title: LocalizedStringKey?
    let panes: [SettingsPane]
}
