import SwiftUI

struct ProBadge: View {
    var body: some View {
        Text("Pro")
            .font(.proBadge)
            .foregroundStyle(.white)
            .badgeChrome(fill: Palette.proGradient)
            .accessibilityLabel(Text("Waft Pro feature"))
    }
}
