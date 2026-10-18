import SwiftUI
import WaftCore

struct WelcomeStep: View {
    let keyTitle: String
    let start: DictationStart

    private var pressTitle: LocalizedStringKey {
        start == .tap ? "Tap \(keyTitle)" : "Hold \(keyTitle)"
    }

    private var releaseTitle: LocalizedStringKey {
        start == .tap ? "Tap again" : "Let go"
    }

    var body: some View {
        OnboardingStep(title: "Welcome to Waft", message: "Dictate in any app instead of typing.") {
            AppIcon(size: Metrics.pageIconSize)
        } content: {
            SettingsCard {
                TileRow(symbolName: "keyboard", tint: .gray, title: pressTitle, detail: "Waft starts listening.")
                RowDivider()
                TileRow(symbolName: "waveform", tint: .red, title: "Speak", detail: "Your speech is recognized on this Mac.")
                RowDivider()
                TileRow(symbolName: "text.cursor", tint: .blue, title: releaseTitle, detail: "The text appears at the cursor.")
            }
        }
    }
}
