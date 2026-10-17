import SwiftUI
import WaftCore

struct GeneralSettingsPane: View {
    @Bindable var settings: SettingsModel

    let permissions: PermissionMonitor
    let interfaceLanguage: InterfaceLanguageModel
    let updates: UpdatesModel

    private var menuBarNote: LocalizedStringKey? {
        settings.settings.showsMenuBarIcon ? nil : "Open Waft again to get to Settings."
    }

    var body: some View {
        SettingsSection("App") {
            ToggleRow("Open at login", isOn: $settings.launchesAtLogin)
            RowDivider()
            ToggleRow("Show in menu bar", isOn: $settings.settings.showsMenuBarIcon, description: menuBarNote)
            RowDivider()
            InterfaceLanguageRow(model: interfaceLanguage)
        }
        .animation(Motion.layout, value: settings.settings.showsMenuBarIcon)

        SettingsSection("Sounds") {
            ToggleRow(
                "Play sounds",
                isOn: $settings.settings.playsSounds,
                description: "A soft click when recording starts and stops.",
            )
            RowDivider()
            ToggleRow(
                "Lower other sounds while recording",
                isOn: $settings.settings.lowersOtherSounds,
                description: "Turns the Mac's volume down by half while you speak, then back up.",
            )
        }

        if updates.isAvailable {
            UpdatesSection(updates: updates)
        }

        SettingsSection("Permissions", subtitle: "Waft needs both to type for you.") {
            DividedForEach(Permission.allCases, id: \.self) { permission in
                PermissionRow(permission: permission, monitor: permissions, description: .verbatim(permission.purpose))
            }
        }
    }
}

private struct InterfaceLanguageRow: View {
    @Bindable var model: InterfaceLanguageModel

    private var current: String {
        guard let chosen = model.chosen else { return String(localized: "Same as macOS") }

        return InterfaceLanguageModel.name(of: chosen)
    }

    private var note: LocalizedStringKey? {
        model.needsRelaunch ? "Relaunch Waft to switch the language." : nil
    }

    var body: some View {
        SettingsRow("App language", description: note) {
            if model.needsRelaunch {
                Button("Relaunch", action: model.relaunch)
                    .transition(.opacity)
            }

            MenuPicker("App language", selection: $model.chosen, current: current) {
                Text("Same as macOS").tag(String?.none)
                Divider()
                ForEach(model.languages, id: \.self) { identifier in
                    Text(InterfaceLanguageModel.name(of: identifier)).tag(String?.some(identifier))
                }
            }
        }
        .animation(Motion.feedback, value: model.needsRelaunch)
    }
}

private struct UpdatesSection: View {
    @Bindable var updates: UpdatesModel

    var body: some View {
        SettingsSection("Updates") {
            ToggleRow("Check for updates automatically", isOn: $updates.checksAutomatically)
            RowDivider()
            SettingsRow(.verbatim(AppVersion.title)) {
                Button("Check Now", action: updates.check)
            }
        }
    }
}
