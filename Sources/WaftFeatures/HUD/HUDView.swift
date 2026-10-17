import SwiftUI

struct HUDView: View {
    private let hud: HUDController
    private let layout: HUDLayout

    private var radius: CGFloat {
        switch hud.content {
        case nil: layout.hasNotch ? 9 : 12
        case .listening: 12
        case .working, .message: 20
        }
    }

    private var contentKey: String {
        switch hud.content {
        case nil: "rest"
        case .listening: "listening"
        case .working: hud.cleanup == nil ? "working" : "cleanup"
        case let .message(message): "message:\(message.title)"
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
        .reducedMotionPolicy()
    }

    private var island: some View {
        let size = layout.contentSize
        let animation = hud.content == nil ? Motion.islandClose : Motion.islandOpen
        let shape = IslandShape(radius: radius)
        let content = HUDIsland(content: hud.content, hud: hud, layout: layout)

        return ZStack(alignment: .top) {
            shape
                .fill(.black)
                .frame(width: size.width + 2 * IslandShape.ear, height: size.height)

            content
                .fixedSize()
                .geometryGroup()
                .id(contentKey)
                .transition(.islandContent)
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
        .animation(animation, value: size)
        .animation(animation, value: contentKey)
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
    fileprivate static var islandContent: AnyTransition {
        .asymmetric(
            insertion: .modifier(active: IslandContentPhase(progress: 0), identity: IslandContentPhase(progress: 1))
                .animation(Motion.islandContent),
            removal: .opacity.animation(Motion.fade),
        )
    }
}
