import Testing
import WaftCore

struct AudioLevelTests {
    @Test(arguments: [([], 0), ([1, -1, 1, -1], 1), ([0.5, -0.5], 0.5)] as [([Float], Float)])
    func `measures the root mean square of samples`(samples: [Float], rms: Float) {
        #expect(AudioLevel.rms(samples) == rms)
    }

    @Test(arguments: [(0, 0), (-1, 0), (0.001, 0), (0.1, 0.6), (1, 1), (2, 1)] as [(Float, Float)])
    func `maps the level onto the meter from -50 dB to full scale`(rms: Float, meter: Float) {
        #expect(abs(AudioLevel.meterValue(rms: rms) - meter) < 0.001)
    }
}
