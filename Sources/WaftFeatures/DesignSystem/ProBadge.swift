import SwiftUI

struct ProBadge: View {
    var body: some View {
        WaftPlusMark(size: 12)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Waft+ feature"))
    }
}
