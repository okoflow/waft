import SwiftUI

struct CheckmarkAppear: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content.transition(.symbolEffect(.drawOn))
        } else {
            content.transition(.symbolEffect(.appear))
        }
    }
}
