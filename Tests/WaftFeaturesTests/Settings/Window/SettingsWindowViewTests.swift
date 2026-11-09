import SwiftUI
import Testing
@testable import WaftFeatures

struct SettingsWindowViewTests {
    @Test
    func `fits the whole sidebar at the minimum size`() {
        let sidebar = NSHostingController(rootView: SettingsSidebar(state: SettingsWindowState()))

        let height = sidebar.sizeThatFits(in: .zero).height + 2 * SettingsWindowView.inset

        #expect(height <= SettingsWindowView.minimumSize.height)
    }
}
