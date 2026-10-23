import SwiftUI
import WaftCore

extension ProModel {
    func optionTitle(of mode: Mode, in settings: WaftCore.Settings) -> Text {
        let title = settings.title(of: mode)

        guard locks(mode) else { return Text(title) }

        return Text("\(title) (Waft+)")
    }
}
