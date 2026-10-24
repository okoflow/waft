import Foundation

package enum AudioLevel {
    private static let meterFloorDecibels: Float = -50

    package static func rootMeanSquare(_ samples: some Collection<Float>) -> Float {
        guard !samples.isEmpty else { return 0 }

        let sumOfSquares = samples.reduce(Float(0)) { $0 + $1 * $1 }

        return (sumOfSquares / Float(samples.count)).squareRoot()
    }

    package static func meterValue(rootMeanSquare: Float) -> Float {
        let normalized = (decibels(rootMeanSquare: rootMeanSquare) - meterFloorDecibels) / -meterFloorDecibels

        return min(1, max(0, normalized))
    }

    static func decibels(rootMeanSquare: Float) -> Float {
        guard rootMeanSquare > 0 else { return -.infinity }

        return 20 * log10(rootMeanSquare)
    }
}
