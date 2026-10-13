import SwiftUI

struct Badge: View {
    private let text: LocalizedStringKey
    private let tint: Color?

    private var foreground: AnyShapeStyle {
        guard let tint else { return AnyShapeStyle(.secondary) }

        return AnyShapeStyle(tint)
    }

    private var fill: Color {
        guard let tint else { return Palette.selection }

        return tint.opacity(0.14)
    }

    init(_ text: LocalizedStringKey, tint: Color? = nil) {
        self.text = text
        self.tint = tint
    }

    var body: some View {
        Text(text)
            .font(.badge)
            .foregroundStyle(foreground)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(fill, in: Capsule())
    }
}
