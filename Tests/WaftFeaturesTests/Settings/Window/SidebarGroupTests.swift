import Testing
@testable import WaftFeatures

struct SidebarGroupTests {
    @Test
    func `lists every pane once`() {
        #expect(SidebarGroup.panes.count == SettingsPane.allCases.count)
        #expect(Set(SidebarGroup.panes) == Set(SettingsPane.allCases))
    }
}
