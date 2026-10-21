package import SwiftUI
import WaftCore

package struct MenuContent: View {
    private let model: AppModel

    private var translatorShortcut: KeyboardShortcut? {
        guard let combination = model.shortcuts.combination(for: .translator) else { return nil }

        return combination.keyboardShortcut(in: model.shortcuts.layout)
    }

    package init(model: AppModel) {
        self.model = model
    }

    package var body: some View {
        Text(model.status.title(in: model.settings.settings))

        if model.needsSetup {
            Button("Finish Setup…", action: model.showSetup)
        }

        if model.speechModelController.state.canRetry {
            Button("Retry Speech Model") { model.speechModelController.retry() }
        }

        if model.updates.hasPendingUpdate {
            Button("Install Update…") { model.updates.check() }
        }

        Divider()

        ModeMenu(settings: model.settings, pro: model.pro, shortcutTitle: model.shortcuts.title(for: .modeCycle)) {
            model.windows.showSettings(.pro)
        }

        if let app = model.frontmostApp.app {
            AppModeMenu(app: app, settings: model.settings, pro: model.pro) { model.windows.showSettings(.pro) }
        }

        LanguageMenu(settings: model.settings) { model.windows.showSettings(.dictation) }

        Divider()

        Button("Copy Last Dictation", action: model.queue.copyLatestTranscript)
            .disabled(model.queue.latestTranscript == nil)

        RecentMenu(history: model.history) { model.windows.showSettings(.history) }

        Button(model.transcription.isLocked ? "Transcribe File (Waft+)…" : "Transcribe File…") {
            model.windows.showTranscription()
        }

        Button(model.translator.isLocked ? "Translator (Waft+)…" : "Translator…") {
            model.windows.showTranslator()
        }
        .keyboardShortcut(translatorShortcut)

        Divider()

        Button("Settings…") { model.windows.showSettings() }
            .keyboardShortcut(",")

        ProMenuItem(pro: model.pro) { model.windows.showSettings(.pro) }

        if model.updates.isAvailable {
            Button("Check for Updates…") { model.updates.check() }
        }

        Divider()

        Button("Quit Waft") { model.quit() }
            .keyboardShortcut("q")
    }
}

private struct ModeMenu: View {
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
                    ModeOption(mode: mode, settings: settings.settings, pro: pro).tag(mode)
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

private struct AppModeMenu: View {
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
                    ModeOption(mode: mode, settings: settings.settings, pro: pro).tag(Mode?.some(mode))
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
    }
}

private struct ModeOption: View {
    let mode: Mode
    let settings: WaftCore.Settings
    let pro: ProModel

    var body: some View {
        let title = settings.title(of: mode)

        if pro.locks(mode) {
            Text("\(title) (Waft+)")
        } else {
            Text(title)
        }
    }
}

private struct LanguageMenu: View {
    let settings: SettingsModel
    let chooseLanguages: () -> Void

    private var languageNames: String {
        settings.settings.languages.languages.map(\.displayName).formatted(.list(type: .and, width: .narrow))
    }

    private var pinnedTitle: String {
        guard let pinned = settings.settings.languages.pinned else { return String(localized: "Automatic") }

        return pinned.displayName
    }

    private var pinned: Binding<Language?> {
        Binding(
            get: { settings.settings.languages.pinned },
            set: { settings.settings.languages = settings.settings.languages.pinning($0) },
        )
    }

    var body: some View {
        Menu("Language: \(pinnedTitle)") {
            Picker("Language", selection: pinned) {
                Text("Automatic (\(languageNames))").tag(Language?.none)
                ForEach(settings.settings.languages.languages, id: \.self) { language in
                    Text(language.displayName).tag(Language?.some(language))
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()

            Divider()

            Button("Choose Languages…", action: chooseLanguages)
        }
    }
}

private struct RecentMenu: View {
    let history: HistoryModel
    let showHistory: () -> Void

    var body: some View {
        Menu("Recent Dictations") {
            let entries = history.recentEntries

            if entries.isEmpty {
                Text("No dictations yet")
            }

            ForEach(entries, id: \.date) { entry in
                Button(entry.preview) { history.copy(entry) }
            }

            Divider()

            Button("Show History", action: showHistory)
        }
    }
}

private struct ProMenuItem: View {
    let pro: ProModel
    let showPro: () -> Void

    var body: some View {
        switch pro.access.status {
        case .trial, .expired:
            Button("Unlock Waft+…", action: showPro)

        case .licensed, .beta:
            EmptyView()
        }
    }
}
