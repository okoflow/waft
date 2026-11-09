import Testing
@testable import WaftFeatures

struct SidebarGroupTests {
    @Test
    func `follows the panes in the order the arrow keys move through them`() {
        #expect((SidebarGroup.top + [SidebarGroup.bottom]).flatMap(\.panes) == SettingsPane.allCases)
    }
}
