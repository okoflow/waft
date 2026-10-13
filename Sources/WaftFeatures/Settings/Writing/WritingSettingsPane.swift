import AppKit
import os
import SwiftUI
import UniformTypeIdentifiers
import WaftCore

struct WritingSettingsPane: View {
    @Bindable var settings: SettingsModel

    let apiKeys: PerProvider<APIKeyModel>
    let shortcutTitle: String?
    let pro: ProModel
    let state: SettingsWindowState

    private var provider: ModelProvider {
        settings.settings.modelProvider
    }

    private var translationNote: LocalizedStringKey {
        let target = settings.settings.translation.target.inlineName

        guard let other = settings.settings.translation.twoWayLanguage?.inlineName else {
            return .verbatim(String(localized: "Translate turns anything you say into \(target)."))
        }

        return .verbatim(String(localized: "Speak \(other) to get \(target), and \(target) to get \(other).").sentenceCased())
    }

    private var modeNote: LocalizedStringKey? {
        guard let shortcutTitle else { return nil }

        return "\(shortcutTitle) switches to the next mode."
    }

    private var setupNote: LocalizedStringKey? {
        AIModelSetup.missingSetup(in: settings, apiKeys: apiKeys)
    }

    private var twoWayTitle: String {
        guard let language = settings.settings.translation.twoWayLanguage else { return String(localized: "Off") }

        return language.displayName
    }

    private var appIdentifiers: [String] {
        settings.settings.appModes.bundleIdentifiers
    }

    var body: some View {
        SettingsSection("Mode", subtitle: modeNote) {
            DividedForEach(Mode.allCases, id: \.self) { mode in
                ModeRow(mode: mode, provider: provider, isLocked: pro.locks(mode), settings: settings, state: state)
            }
        } footer: {
            if let setupNote {
                Text(setupNote)
                    .font(.rowDetail)
                    .foregroundStyle(.secondary)

                Button("Set Up…") { state.selection = .aiModels }
            }
        }

        SettingsSection("Translation", subtitle: translationNote) {
            PickerRow(
                "Translate into",
                selection: $settings.settings.translation.target,
                current: settings.settings.translation.target.displayName,
            ) {
                ForEach(Language.allByDisplayName, id: \.self) { language in
                    Text(language.displayName).tag(language)
                }
            }
            RowDivider()
            PickerRow(
                "Two-way with",
                selection: $settings.settings.translation.twoWayLanguage,
                current: twoWayTitle,
            ) {
                Text("Off").tag(Language?.none)
                Divider()
                ForEach(Language.allByDisplayName.filter { $0 != settings.settings.translation.target }, id: \.self) { language in
                    Text(language.displayName).tag(Language?.some(language))
                }
            }
        }

        SettingsSection("Apps", subtitle: "These apps get their own mode.") {
            if appIdentifiers.isEmpty {
                EmptyRow("No apps yet")
            }

            DividedForEach(appIdentifiers, id: \.self) { bundleIdentifier in
                AppModeRow(bundleIdentifier: bundleIdentifier, settings: settings)
            }
            .rowTransition()
        } footer: {
            Button("Add App…", action: addApp)
        }
        .animation(Motion.layout, value: appIdentifiers)

        SettingsSection("Output") {
            ToggleRow(
                "Paste into the focused field",
                isOn: $settings.settings.pastesIntoFocusedField,
                description: "When off, Waft copies the text and you paste it yourself.",
            )
        }
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

private struct ModeRow: View {
    let mode: Mode
    let provider: ModelProvider
    let isLocked: Bool
    let settings: SettingsModel
    let state: SettingsWindowState

    private var isSelected: Bool {
        settings.settings.mode == mode
    }

    private var isCustomized: Bool {
        mode.usesAI && settings.settings.instructions.isCustomized(mode)
    }

    var body: some View {
        HStack(spacing: Metrics.accessorySpacing) {
            Button {
                if isLocked {
                    state.selection = .pro
                } else {
                    settings.settings.mode = mode
                }
            } label: {
                HStack(spacing: 0) {
                    ModeLabel(mode: mode, provider: provider, isCustomized: isCustomized)

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])

            if isLocked {
                Badge("Pro", tint: .purple)
            } else if mode.usesAI {
                InstructionsButton(mode: mode, provider: provider, settings: settings, state: state)
            }

            ZStack {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.sectionTitle)
                        .foregroundStyle(.tint)
                        .transition(.opacity)
                }
            }
            .frame(width: 14)
            .animation(Motion.feedback, value: isSelected)
            .accessibilityHidden(true)
        }
        .settingsRowPadding()
    }
}

private struct ModeLabel: View {
    let mode: Mode
    let provider: ModelProvider
    let isCustomized: Bool

    private var processingNote: Text {
        provider.isCloud
            ? Text("Sends the recognized text to \(provider.title)")
            : Text("Runs on this Mac with \(provider.title)")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(mode.title)
                    .font(.rowTitle)

                if mode.usesAI {
                    Image(systemName: provider.isCloud ? "cloud" : "cpu")
                        .font(.glyph)
                        .foregroundStyle(.secondary)
                        .help(processingNote)
                        .accessibilityLabel(processingNote)
                }

                if isCustomized {
                    Badge("Edited")
                        .transition(.opacity)
                }
            }

            Text(mode.summary)
                .font(.rowDetail)
                .foregroundStyle(.secondary)
        }
        .animation(Motion.feedback, value: isCustomized)
    }
}

private struct AppModeRow: View {
    let bundleIdentifier: String
    let settings: SettingsModel

    private var mode: Binding<Mode> {
        Binding(
            get: { settings.settings.mode(for: bundleIdentifier) },
            set: { settings.settings.appModes.set($0, for: bundleIdentifier) },
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

            MenuPicker("Mode", selection: mode, current: mode.wrappedValue.title) {
                ForEach(Mode.allCases, id: \.self) { mode in
                    Text(mode.title).tag(mode)
                }
            }

            RemoveButton(help: "Use the default mode in this app") {
                settings.settings.appModes.set(nil, for: bundleIdentifier)
            }
        }
        .settingsRowPadding()
    }
}
