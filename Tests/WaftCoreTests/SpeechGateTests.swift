import Foundation
import Testing
@testable import WaftCore

struct SpeechGateTests {
    private static let sampleRate = SpeechAudio.sampleRate

    @Test(arguments: [0, 1600, 16000])
    func `hears no speech in silence`(count: Int) {
        let samples = [Float](repeating: 0, count: count)

        #expect(!SpeechGate.containsSpeech(samples))
        #expect(SpeechGate.loudDuration(of: samples) == 0)
    }

    @Test(arguments: [0.16, 0.3, 1.0])
    func `hears speech in a loud burst`(seconds: Double) {
        let samples = silence(0.5) + tone(seconds, amplitude: 0.5) + silence(0.5)

        #expect(SpeechGate.containsSpeech(samples))
        #expect(abs(SpeechGate.loudDuration(of: samples) - seconds) < 0.03)
    }

    @Test(arguments: [(0.5, 0.0), (0.0, 0.5)])
    func `hears speech that reaches an edge of the recording`(silenceBefore: Double, silenceAfter: Double) {
        let samples = silence(silenceBefore) + tone(0.3, amplitude: 0.5) + silence(silenceAfter)

        #expect(SpeechGate.containsSpeech(samples))
        #expect(abs(SpeechGate.loudDuration(of: samples) - 0.3) < 0.03)
    }

    @Test
    func `hears speech over a steady background noise`() {
        let burst = silence(0.5) + tone(0.3, amplitude: 0.5) + silence(0.5)

        let samples = zip(tone(1.3, amplitude: 0.01), burst).map(+)

        #expect(SpeechGate.containsSpeech(samples))
        #expect(abs(SpeechGate.loudDuration(of: samples) - 0.3) < 0.03)
    }

    @Test
    func `ignores a burst shorter than the minimum speech duration`() {
        let samples = silence(0.5) + tone(0.1, amplitude: 0.5) + silence(0.5)

        #expect(!SpeechGate.containsSpeech(samples))
    }

    @Test
    func `ignores clicks shorter than a syllable`() {
        let click = tone(0.04, amplitude: 0.8) + silence(0.2)

        let samples = silence(0.5) + Array(Array(repeating: click, count: 10).joined())

        #expect(SpeechGate.loudDuration(of: samples) == 0)
    }

    @Test
    func `treats a steady hum as the noise floor`() {
        #expect(!SpeechGate.containsSpeech(tone(2, amplitude: 0.5)))
    }

    @Test
    func `ignores sound below the absolute floor`() {
        let samples = silence(0.5) + tone(0.5, amplitude: 0.0005) + silence(0.5)

        #expect(!SpeechGate.containsSpeech(samples))
    }

    private func silence(_ seconds: Double) -> [Float] {
        [Float](repeating: 0, count: Int(seconds * Self.sampleRate))
    }

    private func tone(_ seconds: Double, amplitude: Float) -> [Float] {
        (0 ..< Int(seconds * Self.sampleRate)).map { index in
            amplitude * Float(sin(2 * Double.pi * 440 * Double(index) / Self.sampleRate))
        }
    }
}
