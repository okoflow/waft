import SwiftUI

struct UsageStep: View {
    var body: some View {
        OnboardingStep(title: "Help improve Waft", message: "Anonymous usage data shows which features to work on next.") {
            IconTile(symbolName: "chart.bar.fill", tint: .teal, size: Metrics.heroTileSize)
        } content: {
            SettingsCard {
                TileRow(
                    symbolName: "number",
                    tint: .blue,
                    title: "What is sent",
                    detail: "Feature counts, the Waft and macOS versions, and a random ID.",
                )
                RowDivider()
                TileRow(
                    symbolName: "lock.fill",
                    tint: .green,
                    title: "What stays on this Mac",
                    detail: "Your words, audio, dictionary, and the names of apps and files.",
                )
                RowDivider()
                TileRow(
                    symbolName: "gearshape.fill",
                    tint: .gray,
                    title: "Your choice",
                    detail: "Change it anytime in Settings › General.",
                )
            }
        }
    }
}
