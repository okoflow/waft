import Testing
import WaftCore
@testable import WaftFeatures

struct OtherSoundsLoweringTests {
    private let outputVolume = FakeOutputVolume()

    @Test
    func `lowers other sounds to a quarter after the delay`() async {
        let lowering = OtherSoundsLowering(outputVolume: outputVolume, delay: .zero)
        lowering.lower { true }

        #expect(await Poll.until(timeout: .seconds(5)) { outputVolume.isLowered })
        #expect(outputVolume.loweredFractions == [0.25])
    }

    @Test
    func `skips lowering once the recording is no longer wanted`() async throws {
        let lowering = OtherSoundsLowering(outputVolume: outputVolume, delay: .zero)
        lowering.lower { false }

        try await Task.sleep(for: .milliseconds(100))

        #expect(outputVolume.loweredFractions.isEmpty)
    }

    @Test
    func `restoring cancels a pending lowering and brings the volume back`() async throws {
        let pending = OtherSoundsLowering(outputVolume: outputVolume, delay: .seconds(60))
        pending.lower { true }
        pending.restore()

        try await Task.sleep(for: .milliseconds(100))

        #expect(outputVolume.loweredFractions.isEmpty)

        let lowering = OtherSoundsLowering(outputVolume: outputVolume, delay: .zero)
        lowering.lower { true }

        #expect(await Poll.until(timeout: .seconds(5)) { outputVolume.isLowered })

        lowering.restore()

        #expect(!outputVolume.isLowered)
    }
}
