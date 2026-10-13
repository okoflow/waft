import Testing
@testable import WaftFeatures

struct SidebarGroupTests {
    @Test
    func `follows the panes in the order the arrow keys move through them`() {
        #expect(SidebarGroup.all.flatMap(\.panes) + [.pro, .about] == SettingsPane.allCases)
    }
}
