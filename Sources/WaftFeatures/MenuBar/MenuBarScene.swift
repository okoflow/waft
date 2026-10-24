package import SwiftUI
import WaftCore

package struct MenuBarScene: Scene {
    private let model: AppModel

    package var body: some Scene {
        let settings = model.settings

        let isShown = settings.settings.showsMenuBarIcon

        let isInserted = Binding(
            get: { isShown },
            set: { newValue in
                guard newValue != settings.settings.showsMenuBarIcon else { return }

                settings.settings.showsMenuBarIcon = newValue
            },
        )

        MenuBarExtra(isInserted: isInserted) {
            MenuContent(model: model)
        } label: {
            MenuBarIcon()
        }
        .menuBarExtraStyle(.menu)
    }

    package init(model: AppModel) {
        self.model = model
    }
}
