import Foundation

enum Shimmer {
    static let width = 0.2

    private static let period: TimeInterval = 1.6

    static func center(at time: TimeInterval) -> Double {
        let phase = time.truncatingRemainder(dividingBy: period) / period

        return -0.3 + 1.6 * phase
    }
}
