import SwiftUI

struct SettingsWindowView: View {
    private static let sidebarWidth: CGFloat = 222
    private static let inset: CGFloat = 8

    let model: AppModel
    let state: SettingsWindowState

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(state: state)
                .frame(width: Self.sidebarWidth)
                .padding([.leading, .vertical], Self.inset)

            SettingsPaneView(model: model, state: state)
        }
        .windowChrome()
    }
}
