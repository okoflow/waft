import SwiftUI

enum BrandGlow {
    static let base = LinearGradient(colors: [Color(hex: 0x34343A), Color(hex: 0x16161A)], startPoint: .top, endPoint: .bottom)

    static let blue = glow(0x3B82F6, at: UnitPoint(x: 0.9, y: 0), reach: 0.8, opacities: [(0.45, 0), (0.14, 0.5), (0, 1)])
    static let pink = glow(0xDB2777, at: UnitPoint(x: 0.05, y: 1), reach: 0.85, opacities: [(0.5, 0), (0.16, 0.5), (0, 1)])
    static let violet = glow(
        0x7C3AED,
        at: UnitPoint(x: 0.95, y: 1),
        reach: 1.05,
        opacities: [(0.9, 0), (0.5, 0.35), (0.18, 0.65), (0, 1)],
    )

    private static func glow(
        _ hex: UInt32,
        at center: UnitPoint,
        reach: CGFloat,
        opacities: [(Double, CGFloat)],
    ) -> EllipticalGradient {
        let stops = opacities.map { Gradient.Stop(color: Color(hex: hex).opacity($0.0), location: $0.1) }

        return EllipticalGradient(stops: stops, center: center, endRadiusFraction: reach)
    }
}

extension View {
    func brandGlow(in shape: some InsettableShape) -> some View {
        background {
            ZStack {
                shape.fill(BrandGlow.base)
                shape.fill(BrandGlow.blue)
                shape.fill(BrandGlow.pink)
                shape.fill(BrandGlow.violet)
                shape.strokeBorder(.white.opacity(0.18), lineWidth: 0.8)
            }
            .environment(\.layoutDirection, .leftToRight)
        }
    }
}
