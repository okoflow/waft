import SwiftUI

struct HUDView: View {
    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    private let hud: HUDController
    private let layout: HUDLayout

    private var radius: CGFloat {
        switch hud.content {
        case nil: layout.hasNotch ? 9 : 12
        case .listening: 12
        case .working: 20
        case .message: hud.showsCompactMessage ? 12 : 20
        }
    }

    private var contentKey: String {
        switch hud.content {
        case nil: "rest"
        case .listening: "listening"
        case .working: "working"
        case let .message(message): "message:\(message.title):\(hud.showsCompactMessage)"
        }
    }

    init(hud: HUDController, layout: HUDLayout) {
        self.hud = hud
        self.layout = layout
    }

    var body: some View {
        VStack(spacing: 0) {
            island

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.colorScheme, .dark)
    }

    private var island: some View {
        let size = layout.contentSize
        let animation = hud.content == nil ? Motion.islandClose : Motion.islandOpen
        let shape = IslandShape(radius: radius, isFloating: layout.isFloating)
        let ears = layout.isFloating ? 0 : 2 * IslandShape.ear
        let content = HUDIsland(content: hud.content, hud: hud, layout: layout)

        return ZStack(alignment: .top) {
            shape
                .fill(.black)
                .frame(width: size.width + ears, height: size.height)

            content
                .fixedSize()
                .geometryGroup()
                .id(contentKey)
                .transition(.islandContent(reducesMotion: reducesMotion))
                .frame(width: size.width, height: size.height, alignment: .top)
        }
        .clipShape(shape)
        .background(alignment: .top) {
            content
                .fixedSize()
                .hidden()
                .accessibilityHidden(true)
                .onGeometryChange(for: CGSize.self) { $0.size } action: { layout.contentSize = $0 }
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { layout.islandFrame = $0 }
        .motion(animation, value: size)
        .motion(animation, value: contentKey)
    }
}

private struct IslandContentPhase: ViewModifier {
    let progress: Double

    func body(content: Content) -> some View {
        content
            .opacity(progress)
            .blur(radius: 4 * (1 - progress))
            .scaleEffect(0.9 + 0.1 * progress, anchor: .top)
    }
}

extension AnyTransition {
    fileprivate static func islandContent(reducesMotion: Bool) -> AnyTransition {
        .asymmetric(
            insertion: islandInsertion(reducesMotion: reducesMotion)
                .animation(Motion.adapted(Motion.islandContent, reducesMotion: reducesMotion)),
            removal: .opacity.animation(Motion.adapted(Motion.fade, reducesMotion: reducesMotion)),
        )
    }

    private static func islandInsertion(reducesMotion: Bool) -> AnyTransition {
        guard !reducesMotion else { return .opacity }

        return .modifier(active: IslandContentPhase(progress: 0), identity: IslandContentPhase(progress: 1))
    }
}
