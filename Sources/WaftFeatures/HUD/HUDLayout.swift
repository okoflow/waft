import CoreGraphics
import Observation

@Observable
final class HUDLayout {
    nonisolated static let wing: CGFloat = 62

    private static let rowHeight: CGFloat = 32

    private(set) var gap: CGFloat = 0
    private(set) var topHeight = rowHeight
    private(set) var hasNotch = false
    private(set) var isFloating = false
    var contentSize = CGSize.zero

    @ObservationIgnored var islandFrame: CGRect?

    var spanWidth: CGFloat {
        2 * Self.wing + gap
    }

    var restWidth: CGFloat {
        hasNotch ? gap : spanWidth
    }

    var restHeight: CGFloat {
        hasNotch ? topHeight : 0
    }

    func place(around notch: CGSize?) {
        isFloating = false
        arrange(around: notch)
    }

    func placeBelowMenuBar() {
        isFloating = true
        arrange(around: nil)
    }

    private func arrange(around notch: CGSize?) {
        hasNotch = notch != nil
        gap = 0
        topHeight = Self.rowHeight

        if let notch {
            gap = notch.width
            topHeight = max(Self.rowHeight, notch.height)
        }

        contentSize = CGSize(width: restWidth, height: restHeight)
    }
}
