import SwiftUI

nonisolated struct IslandRow: Layout {
    private static let notchSpacing: CGFloat = 10

    let gap: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout Void) -> CGSize {
        let width = max(2 * wingWidth(of: subviews) + gap, finite(proposal.width))
        let height = subviews.map { $0.sizeThatFits(.unspecified).height }.max()
        guard let height else { return CGSize(width: width, height: 0) }

        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout Void) {
        let size = ProposedViewSize(width: wingWidth(of: subviews), height: bounds.height)

        guard let leading = subviews.first else { return }

        leading.place(at: CGPoint(x: bounds.minX, y: bounds.midY), anchor: .leading, proposal: size)

        guard let trailing = subviews.last, subviews.count > 1 else { return }

        trailing.place(at: CGPoint(x: bounds.maxX, y: bounds.midY), anchor: .trailing, proposal: size)
    }

    private func finite(_ length: CGFloat?) -> CGFloat {
        guard let length, length.isFinite else { return 0 }

        return length
    }

    private func wingWidth(of subviews: Subviews) -> CGFloat {
        let widest = subviews.map { $0.sizeThatFits(.unspecified).width }.max()
        guard let widest else { return HUDLayout.wing }

        return max(HUDLayout.wing, ceil(widest) + Self.notchSpacing)
    }
}
