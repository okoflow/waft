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
    func `skips lowering once the recording is no longer wanted`() async {
        let lowering = OtherSoundsLowering(outputVolume: outputVolume, delay: .zero)

        lowering.lower { false }

        #expect(await !Poll.until(timeout: .milliseconds(300)) { !outputVolume.loweredFractions.isEmpty })
    }

    @Test
    func `cancels a pending lowering and brings the volume back on restore`() async {
        let pending = OtherSoundsLowering(outputVolume: outputVolume, delay: .zero)

        pending.lower { true }
        pending.restore()

        #expect(await !Poll.until(timeout: .milliseconds(300)) { !outputVolume.loweredFractions.isEmpty })

        let lowering = OtherSoundsLowering(outputVolume: outputVolume, delay: .zero)

        lowering.lower { true }

        #expect(await Poll.until(timeout: .seconds(5)) { outputVolume.isLowered })

        lowering.restore()

        #expect(!outputVolume.isLowered)
    }
}
