import WaftCore

final class FakeOutputVolume: OutputVolume {
    private(set) var loweredFractions: [Float] = []
    private(set) var restoreCount = 0

    var isLowered: Bool {
        loweredFractions.count > restoreCount
    }

    func lower(to fraction: Float) {
        loweredFractions.append(fraction)
    }

    func restore() {
        guard isLowered else { return }

        restoreCount += 1
    }
}
