import SwiftUI

struct SettingsPaneView: View {
    private let model: AppModel
    private let state: SettingsWindowState

    init(model: AppModel, state: SettingsWindowState) {
        self.model = model
        self.state = state
    }

    var body: some View {
        SettingsPage(.verbatim(state.selection.title)) {
            content
        }
        .id(state.selection)
    }

    @ViewBuilder
    private var content: some View {
        switch state.selection {
        case .overview:
            OverviewSettingsPane(stats: model.stats)

        case .general:
            GeneralSettingsPane(
                settings: model.settings,
                permissions: model.permissions,
                interfaceLanguage: model.interfaceLanguage,
                updates: model.updates,
            )

        case .dictation:
            DictationSettingsPane(settings: model.settings, keyRecorder: model.keyRecorder, pro: model.pro, state: state)

        case .writing:
            WritingSettingsPane(
                settings: model.settings,
                apiKeys: model.apiKeys,
                shortcutTitle: model.modeSwitcher.shortcutTitle,
                pro: model.pro,
                state: state,
            )

        case .aiModels:
            AIModelsSettingsPane(
                settings: model.settings,
                speechModel: model.speechModel,
                apiKeys: model.apiKeys,
                localModels: model.localModels,
            )

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
