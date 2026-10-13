import SwiftUI

struct WelcomeStep: View {
    let keyTitle: String

    var body: some View {
        OnboardingStep(title: "Welcome to Waft", message: "Dictate in any app instead of typing.") {
            AppIcon(size: 96)
        } content: {
            SettingsCard {
                TileRow(symbolName: "keyboard", tint: .gray, title: "Hold \(keyTitle)", detail: "Waft starts listening")
                RowDivider()
                TileRow(symbolName: "waveform", tint: .red, title: "Speak", detail: "Your speech is recognized on this Mac")
                RowDivider()
                TileRow(symbolName: "text.cursor", tint: .blue, title: "Let go", detail: "The text appears at the cursor")
            }
        }
    }
}
