import SwiftUI

struct WaftPlusMark: View {
    let size: CGFloat

    var body: some View {
        PlusShape()
            .stroke(.white, style: StrokeStyle(lineWidth: size * 0.105, lineCap: .round))
            .frame(width: size, height: size)
            .brandGlow(in: Circle())
            .accessibilityHidden(true)
    }
}

private nonisolated struct PlusShape: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = rect.width * 0.29
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - inset))
        path.move(to: CGPoint(x: rect.minX + inset, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.midY))

        return path
    }
}
