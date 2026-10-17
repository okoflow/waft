import SwiftUI

nonisolated struct IslandShape: Shape {
    static let ear: CGFloat = 6

    var radius: CGFloat

    var animatableData: CGFloat {
        get { radius }
        set { radius = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let ear = min(Self.ear, rect.height)
        let corner = max(0, min(radius, rect.height - ear))
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.minX + ear, y: rect.minY + ear), control: CGPoint(x: rect.minX + ear, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + ear, y: rect.maxY - corner))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + ear + corner, y: rect.maxY),
            control: CGPoint(x: rect.minX + ear, y: rect.maxY),
        )
        path.addLine(to: CGPoint(x: rect.maxX - ear - corner, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - ear, y: rect.maxY - corner),
            control: CGPoint(x: rect.maxX - ear, y: rect.maxY),
        )
        path.addLine(to: CGPoint(x: rect.maxX - ear, y: rect.minY + ear))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.maxX - ear, y: rect.minY))
        path.closeSubpath()

        return path
    }
}
