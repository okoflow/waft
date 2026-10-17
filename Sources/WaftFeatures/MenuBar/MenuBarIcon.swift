package import SwiftUI

package struct MenuBarIcon: View {
    package init() {}

    package var body: some View {
        Image(nsImage: WaftMark.image)
            .accessibilityLabel("Waft")
    }
}
