import SwiftUI

struct SidebarGroup {
    static let all = [
        SidebarGroup(title: nil, panes: [.overview]),
        SidebarGroup(title: "Voice", panes: [.dictation, .dictionary]),
        SidebarGroup(title: "Text", panes: [.writing, .aiModels]),
        SidebarGroup(title: "App", panes: [.history, .general]),
    ]

    let title: LocalizedStringKey?
    let panes: [SettingsPane]
}
