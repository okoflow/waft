import SwiftUI

struct MenuBarIcon: View {
    var body: some View {
        Image(nsImage: WaftMark.image)
            .accessibilityLabel("Waft")
    }
}
