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
            .badgeChrome(fill: Palette.selection)
    }
}

extension View {
    func badgeChrome(fill: some ShapeStyle) -> some View {
        padding(.horizontal, Metrics.badgeHorizontalPadding)
            .padding(.vertical, Metrics.badgeVerticalPadding)
            .background(fill, in: Capsule())
    }
}
