import Observation

@Observable
final class LanguagePickerState {
    var isPresented = false {
        didSet { reset() }
    }

    var query = ""

    private(set) var hoveredRow: String?

    func hover(_ row: String, _ isHovered: Bool) {
        if isHovered {
            hoveredRow = row
        } else if hoveredRow == row {
            hoveredRow = nil
        }
    }

    private func reset() {
        query = ""
        hoveredRow = nil
    }
}
