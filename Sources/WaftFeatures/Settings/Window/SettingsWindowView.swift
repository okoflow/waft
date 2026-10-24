import SwiftUI

struct SettingsWindowView: View {
    let model: AppModel
    let state: SettingsWindowState

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(state: state)
                .frame(width: Metrics.sidebarWidth)
                .padding([.leading, .vertical], Metrics.windowInset)

            SettingsPaneView(model: model, state: state)
        }
        .windowChrome()
    }
}
