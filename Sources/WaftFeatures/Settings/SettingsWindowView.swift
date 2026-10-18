import SwiftUI

struct SettingsWindowView: View {
    private let model: AppModel
    private let state: SettingsWindowState

    init(model: AppModel, state: SettingsWindowState) {
        self.model = model
        self.state = state
    }

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
