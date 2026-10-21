import SwiftUI

struct ResetInstructionsButton: View {
    let title: String
    let isCustomized: Bool
    let reset: () -> Void

    var body: some View {
        Button("Reset to Default…", role: .destructive, action: confirm)
            .disabled(!isCustomized)
    }

    private func confirm() {
        let confirmation = Confirmation(
            message: String(localized: "Reset the instructions of “\(title)”?"),
            detail: String(localized: "Your changes to these instructions are deleted."),
            action: String(localized: "Reset to Default"),
        )

        guard confirmation.ask() else { return }

        reset()
    }
}
