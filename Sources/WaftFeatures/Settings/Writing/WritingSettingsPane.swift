import AppKit
import os
import SwiftUI
import UniformTypeIdentifiers
import WaftCore

struct WritingSettingsPane: View {
    @Bindable var settings: SettingsModel

    let apiKeys: PerProvider<APIKeyModel>
    let shortcuts: GlobalShortcutController
    let shortcutRecorder: ShortcutRecorder
    let pro: ProModel
    let state: SettingsWindowState

    private var translationNote: LocalizedStringKey {
        let target = settings.settings.translation.target.inlineName

        guard let other = settings.settings.translation.twoWayLanguage?.inlineName else {
            return .verbatim(String(localized: "Translate turns anything you say into \(target)."))
        }

        return .verbatim(String(localized: "Speak \(other) to get \(target), and \(target) to get \(other).").sentenceCased())
    }

    private var appIdentifiers: [String] {
        settings.settings.appModes.bundleIdentifiers
    }

    var body: some View {
        ModelSetupSection("Modes", setup: .modes, settings: settings, apiKeys: apiKeys, state: state) {
            DividedForEach(Mode.builtIn, id: \.self) { mode in
                ModeRow(mode: mode, settings: settings, isLocked: pro.locks(mode), state: state)
            }
        }

        SettingsSection("Your modes", subtitle: "Write instructions once and dictate in your own style.", isPro: true) {
            if settings.settings.customModes.isEmpty {
                EmptyRow("No modes yet")
            }

            DividedForEach(settings.settings.customModeChoices, id: \.self) { mode in
                ModeRow(mode: mode, settings: settings, isLocked: pro.locks(mode), state: state)
            }
            .rowTransition()
        } footer: {
            Button("New Mode", action: addMode)
        }
        .motion(Motion.layout, value: settings.settings.customModes)

        SettingsSection("Shortcut", subtitle: "It works in any app.") {
            ShortcutRow(action: .modeCycle, settings: settings, shortcuts: shortcuts, recorder: shortcutRecorder)
        }
        .onDisappear { shortcutRecorder.stop() }

        TranslationSection(
            title: "Translation",
            subtitle: translationNote,
            isPro: true,
            translation: $settings.settings.translation,
        )

        SettingsSection("Apps", subtitle: "These apps get their own mode.") {
            if appIdentifiers.isEmpty {
                EmptyRow("No apps yet")
            }

            DividedForEach(appIdentifiers, id: \.self) { bundleIdentifier in
                AppModeRow(bundleIdentifier: bundleIdentifier, settings: settings, pro: pro, state: state)
            }
            .rowTransition()
        } footer: {
            Button("Add App…", action: addApp)
        }
        .motion(Motion.layout, value: appIdentifiers)

        SettingsSection("Output") {
            ToggleRow(
                "Paste into the focused field",
                isOn: $settings.settings.pastesIntoFocusedField,
                description: "When off, Waft copies the text and you paste it yourself.",
            )
        }
    }

    private func addMode() {
        guard state.passesWaftPlusGate(isUnlocked: pro.isUnlocked) else { return }

        let custom = settings.settings.addCustomMode(named: String(localized: "New Mode"))

        state.editedMode = .custom(custom.id)
    }

    private func addApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(filePath: "/Applications")
        panel.prompt = String(localized: "Add")

        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let bundleIdentifier = Bundle(url: url)?.bundleIdentifier else {
            Logger.settings.error("The chosen app has no bundle identifier")
            NSSound.beep()

            return
        }

        settings.settings.appModes.set(settings.settings.mode, for: bundleIdentifier)
    }
}

private struct AppModeRow: View {
    let bundleIdentifier: String
    let settings: SettingsModel
    let pro: ProModel
    let state: SettingsWindowState

    private var mode: Binding<Mode> {
        Binding(
            get: { settings.settings.mode(for: bundleIdentifier) },
            set: { mode in
                guard state.passesWaftPlusGate(isUnlocked: !pro.locks(mode)) else { return }

                settings.settings.appModes.set(mode, for: bundleIdentifier)
            },
        )
    }

    var body: some View {
        HStack(spacing: Metrics.iconLabelSpacing) {
            Image(nsImage: InstalledApp.icon(of: bundleIdentifier))
                .resizable()
                .frame(width: Metrics.tileSize, height: Metrics.tileSize)
                .accessibilityHidden(true)

            Text(InstalledApp.name(of: bundleIdentifier))
                .font(.rowTitle)

            Spacer(minLength: Metrics.rowSpacing)

            HStack(spacing: Metrics.controlSpacing) {
                MenuPicker("Mode", selection: mode, current: settings.settings.title(of: mode.wrappedValue)) {
                    ForEach(settings.settings.modes, id: \.self) { mode in
                        optionTitle(of: mode).tag(mode)
                    }
                }

                RemoveButton(help: "Use the default mode in this app") {
                    settings.settings.appModes.set(nil, for: bundleIdentifier)
                }
            }
        }
        .settingsRowPadding()
    }

    private func optionTitle(of mode: Mode) -> Text {
        let title = settings.settings.title(of: mode)

        guard pro.locks(mode) else { return Text(title) }

        return Text("\(title) (Waft+)")
    }
}
