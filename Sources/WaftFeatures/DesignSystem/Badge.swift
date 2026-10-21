import SwiftUI

struct Badge: View {
    private let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.badge)
            .foregroundStyle(Palette.secondaryText)
            .padding(.horizontal, Metrics.badgeHorizontalPadding)
            .padding(.vertical, Metrics.badgeVerticalPadding)
            .background(Palette.selection, in: Capsule())
    }
}
