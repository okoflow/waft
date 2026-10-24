import Observation

@Observable
final class LanguagePickerState {
    var isPresented = false {
        didSet { reset() }
    }

    var query = ""

    private(set) var hoveredRow: String?

    func hover(_ row: String, _ isHovered: Bool) {
        guard !isHovered else {
            hoveredRow = row

            return
        }
        guard hoveredRow == row else { return }

        hoveredRow = nil
    }

    private func reset() {
        query = ""
        hoveredRow = nil
    }
}
