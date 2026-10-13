import AppKit
import SwiftUI

private struct HUDBackground: ViewModifier {
    private static let padding = EdgeInsets(top: 11, leading: 18, bottom: 11, trailing: 18)
    private static let minimumHeight: CGFloat = 44

    func body(content: Content) -> some View {
        let pill = content
            .padding(Self.padding)
            .frame(minHeight: Self.minimumHeight)

        if #available(macOS 26, *) {
            pill.glassEffect(.regular, in: .capsule)
        } else {
            pill
                .environment(\.colorScheme, .dark)
                .background(VisualEffectBackground().clipShape(Capsule()))
                .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
        }
    }
}

private struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context _: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active

        return view
    }

    func updateNSView(_: NSVisualEffectView, context _: Context) {}
}

extension View {
    func hudBackground() -> some View {
        modifier(HUDBackground())
    }
}
