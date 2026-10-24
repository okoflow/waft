import Testing
import WaftCore

struct AudioLevelTests {
    @Test(arguments: [([], 0), ([1, -1, 1, -1], 1), ([0.5, -0.5], 0.5)] as [([Float], Float)])
    func `measures the root mean square of samples`(samples: [Float], rootMeanSquare: Float) {
        #expect(AudioLevel.rootMeanSquare(samples) == rootMeanSquare)
    }

    @Test(arguments: [(0, 0), (-1, 0), (0.001, 0), (0.1, 0.6), (1, 1), (2, 1)] as [(Float, Float)])
    func `maps the level onto the meter from -50 dB to full scale`(rootMeanSquare: Float, meter: Float) {
        #expect(abs(AudioLevel.meterValue(rootMeanSquare: rootMeanSquare) - meter) < 0.001)
    }
}
