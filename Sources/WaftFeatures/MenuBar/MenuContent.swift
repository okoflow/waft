import SwiftUI
import WaftCore

struct MenuContent: View {
    let model: AppModel

    private var translatorShortcut: KeyboardShortcut? {
        guard let combination = model.shortcuts.combination(for: .translator) else { return nil }

        return combination.keyboardShortcut(in: model.shortcuts.layout)
    }

    var body: some View {
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
            model.showSettings(.pro)
        }

        if let app = model.frontmostApp.app {
            AppModeMenu(app: app, settings: model.settings, pro: model.pro) { model.showSettings(.pro) }
        }

        LanguageMenu(settings: model.settings) { model.showSettings(.dictation) }

        Divider()

        if model.queue.canRetry {
            Button("Retry Last Dictation", action: model.queue.retryFailedDictation)
        }

        Button("Copy Last Dictation", action: model.queue.copyLatestTranscript)
            .disabled(model.queue.latestTranscript == nil)

        RecentMenu(history: model.history) { model.showSettings(.history) }

        Button(model.transcription.isLocked ? "Transcribe File (Waft+)…" : "Transcribe File…") {
            model.showTranscription()
        }

        Button(model.translator.isLocked ? "Translator (Waft+)…" : "Translator…") {
            model.showTranslator()
        }
        .keyboardShortcut(translatorShortcut)

        Divider()

        Button("Settings…") { model.showSettings() }
            .keyboardShortcut(",")

        ProMenuItem(pro: model.pro) { model.showSettings(.pro) }

        if model.updates.isAvailable {
            Button("Check for Updates…") { model.updates.check() }
        }

        Divider()

        Button("Quit Waft") { model.quit() }
            .keyboardShortcut("q")
    }
}
