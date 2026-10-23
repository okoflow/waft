import Foundation
import WaftCore

extension AppModel {
    static func makeTranslator(_ dependencies: AppDependencies, settings: SettingsModel, pro: ProModel) -> TranslatorModel {
        TranslatorModel(
            rewriters: dependencies.rewriters,
            detector: dependencies.languageDetector,
            settings: settings,
            pro: pro,
            clipboard: dependencies.clipboard,
        )
    }

    static func makeTranslatorShortcuts(
        _ dependencies: AppDependencies,
        _ shortcuts: GlobalShortcutController,
        settings: SettingsModel,
        pro: ProModel,
        hud: HUDController,
    ) -> TranslatorShortcuts {
        let actions = SelectionActions(
            rewriters: dependencies.rewriters,
            detector: dependencies.languageDetector,
            focusTracker: dependencies.focusTracker,
            keyboardState: dependencies.keyboardState,
            inserter: dependencies.inserter,
            clipboard: dependencies.clipboard,
            settings: settings,
            pro: pro,
            hud: hud,
        )

        return TranslatorShortcuts(shortcuts: shortcuts, selectionActions: actions)
    }
}
