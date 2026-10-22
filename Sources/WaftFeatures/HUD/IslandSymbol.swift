import SwiftUI

struct IslandSymbol: View {
    private static let width: CGFloat = 18

    let name: String

    var body: some View {
        Image(systemName: name)
            .frame(width: Self.width)
            .accessibilityHidden(true)
    }
}
