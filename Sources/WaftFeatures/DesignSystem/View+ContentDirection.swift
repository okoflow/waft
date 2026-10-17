import SwiftUI
import WaftCore

private struct ContentDirection: ViewModifier {
    @Environment(\.layoutDirection) private var inherited

    let text: String

    private var direction: LayoutDirection {
        guard let script = WritingScript.dominant(in: text) else { return inherited }

        return script.isRightToLeft ? .rightToLeft : .leftToRight
    }

    func body(content: Content) -> some View {
        content.environment(\.layoutDirection, direction)
    }
}

extension View {
    func contentDirection(of text: String) -> some View {
        modifier(ContentDirection(text: text))
    }
}
