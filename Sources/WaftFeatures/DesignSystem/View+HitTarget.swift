import SwiftUI

extension View {
    func widenedHitTarget() -> some View {
        padding(Metrics.hitTargetOutset)
            .contentShape(Rectangle())
            .padding(-Metrics.hitTargetOutset)
    }
}
