import SwiftUI

@MainActor
extension RoundedRectangle {
    static var card: RoundedRectangle {
        RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
    }
}
