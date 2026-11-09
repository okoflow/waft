import SwiftUI

struct SettingsWindowView: View {
    static let minimumSize = CGSize(width: 760, height: 580)
    static let inset: CGFloat = 8

    private static let sidebarWidth: CGFloat = 222

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
