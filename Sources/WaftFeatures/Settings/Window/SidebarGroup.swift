import SwiftUI

struct SidebarGroup {
    static let top = [
        SidebarGroup(title: nil, panes: [.overview, .history]),
        SidebarGroup(title: "Voice", panes: [.dictation, .dictionary]),
        SidebarGroup(title: "Text", panes: [.writing, .translator, .aiModels]),
    ]

    static let bottom = SidebarGroup(title: "App", panes: [.general, .pro, .about])

    let title: LocalizedStringKey?
    let panes: [SettingsPane]
}
