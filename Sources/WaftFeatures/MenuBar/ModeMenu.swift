import SwiftUI
import WaftCore

struct ModeMenu: View {
    let settings: SettingsModel
    let pro: ProModel
    let shortcutTitle: String?
    let showPro: () -> Void

    private var mode: Binding<Mode> {
        Binding(
            get: { settings.settings.mode },
            set: { mode in
                guard !pro.locks(mode) else {
                    showPro()

                    return
                }

                settings.settings.mode = mode
            },
        )
    }

    var body: some View {
        Menu("Mode: \(settings.settings.title(of: settings.settings.mode))") {
            Picker("Mode", selection: mode) {
                ForEach(settings.settings.modes, id: \.self) { mode in
                    pro.optionTitle(of: mode, in: settings.settings).tag(mode)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()

            if let shortcutTitle {
                Divider()

                Text("Next mode: \(shortcutTitle)")
            }
        }
    }
}
