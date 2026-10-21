import SwiftUI

struct SettingsPaneView: View {
    private let model: AppModel
    private let state: SettingsWindowState

    init(model: AppModel, state: SettingsWindowState) {
        self.model = model
        self.state = state
    }

    var body: some View {
        if let mode = state.editedMode, state.selection == .writing {
            ModeEditorPage(mode: mode, settings: model.settings, tryout: model.modeTryout, state: state)
                .id(mode)
        } else {
            SettingsPage(.verbatim(state.selection.title), needsWaftPlus: state.selection.needsWaftPlus) {
                content
            }
            .id(state.selection)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state.selection {
        case .overview:
            OverviewSettingsPane(statistics: model.statistics)

        case .general:
            GeneralSettingsPane(
                settings: model.settings,
                permissions: model.permissions,
                interfaceLanguage: model.interfaceLanguage,
                updates: model.updates,
            )

        case .dictation:
            DictationSettingsPane(
                settings: model.settings,
                speechModelController: model.speechModelController,
                keyRecorder: model.keyRecorder,
                pro: model.pro,
                state: state,
            )

        case .writing:
            WritingSettingsPane(
                settings: model.settings,
                apiKeys: model.apiKeys,
                shortcutTitle: model.modeSwitcher.shortcutTitle,
                pro: model.pro,
                state: state,
            )

        case .translator:
            TranslatorSettingsPane(settings: model.settings, shortcuts: model.translatorShortcuts) {
                model.windows.showTranslator()
            }

        case .aiModels:
            AIModelsSettingsPane(settings: model.settings, apiKeys: model.apiKeys, localModels: model.localModels)

        case .dictionary:
            DictionarySettingsPane(vocabulary: model.vocabulary)

        case .history:
            HistorySettingsPane(settings: model.settings, history: model.history, state: state)

        case .pro:
            ProSettingsPane(pro: model.pro)

        case .about:
            AboutSettingsPane()
        }
    }
}
