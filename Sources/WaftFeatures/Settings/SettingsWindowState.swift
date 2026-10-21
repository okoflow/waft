import Foundation
import Observation
import WaftCore

@Observable
final class SettingsWindowState {
    var selection = SettingsPane.overview {
        didSet { closeEditor() }
    }

    var editedMode: Mode?
    var editedTextTask: TextTask.Kind?

    let copiedEntries = CopyFeedback<Date>()

    var hoveredPane: SettingsPane?

    func closeEditor() {
        editedMode = nil
        editedTextTask = nil
    }

    func passesWaftPlusGate(isUnlocked: Bool) -> Bool {
        if !isUnlocked {
            selection = .pro
        }

        return isUnlocked
    }

    func move(by offset: Int) {
        let panes = SettingsPane.allCases
        guard let index = panes.firstIndex(of: selection) else { return }

        selection = panes[min(max(index + offset, 0), panes.count - 1)]
    }

    func hover(_ pane: SettingsPane, _ isHovering: Bool) {
        if isHovering {
            hoveredPane = pane
        } else if hoveredPane == pane {
            hoveredPane = nil
        }
    }
}
