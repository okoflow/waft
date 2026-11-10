import SwiftUI
import WaftCore

struct AppModeMenu: View {
    let app: RunningApp
    let settings: SettingsModel
    let pro: ProModel
    let showPro: () -> Void

    private var ownMode: Mode? {
        settings.settings.appModes.mode(for: app.bundleIdentifier)
    }

    private var ownModeTitle: String {
        guard let ownMode else { return String(localized: "Default") }

        return settings.settings.title(of: ownMode)
    }

    private var mode: Binding<Mode?> {
        Binding(
            get: { ownMode },
            set: { mode in
                if let mode, pro.locks(mode) {
                    showPro()

                    return
                }

                settings.settings.appModes.set(mode, for: app.bundleIdentifier)
            },
        )
    }

    var body: some View {
        Menu("Mode in \(app.name): \(ownModeTitle)") {
            Picker("Mode in \(app.name)", selection: mode) {
                Text("Default (\(settings.settings.title(of: settings.settings.mode)))").tag(Mode?.none)

                ForEach(settings.settings.modes, id: \.self) { mode in
                    pro.optionTitle(of: mode, in: settings.settings).tag(Mode?.some(mode))
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
    }
}
