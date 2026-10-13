import AVFoundation
import os
import Testing
import WaftCore
@testable import WaftPlatform

struct AudioSampleSinkTests {
    private static let time = AVAudioTime(hostTime: AVAudioTime.hostTime(forSeconds: 100))

    @Test(arguments: [(16000, [0.4]), (44100, [0.6, 0.2]), (48000, [0.6, 0.2])] as [(Double, [Float])])
    func `converts the input to 16 kHz mono`(sampleRate: Double, channelLevels: [Float]) throws {
        let buffer = try AVAudioPCMBuffer.constant(levels: channelLevels, seconds: 0.1, sampleRate: sampleRate)
        let sink = try #require(AudioSampleSink(inputFormat: buffer.format, meter: LevelMeter()) {})

        for _ in 0 ..< 10 {
            sink.consume(buffer, at: Self.time)
        }

        let lastSample = try #require(sink.samples.last)

        #expect((15500 ... 16000).contains(sink.samples.count))
        #expect(abs(lastSample - 0.4) < 0.001)
    }

    @Test
    func `calls the first buffer handler only for the first buffer with audio`() throws {
        let starts = OSAllocatedUnfairLock(initialState: 0)
        let buffer = try AVAudioPCMBuffer.constant(levels: [0.4], seconds: 0.1, sampleRate: SpeechAudio.sampleRate)
        let empty = try AVAudioPCMBuffer.constant(levels: [0.4], seconds: 0.1, sampleRate: SpeechAudio.sampleRate)
        let sink = try #require(AudioSampleSink(inputFormat: buffer.format, meter: LevelMeter()) { starts.withLock { $0 += 1 } })
        empty.frameLength = 0

        sink.consume(empty, at: Self.time)

        #expect(!sink.hasAudio)
        #expect(starts.withLock { $0 } == 0)

        sink.consume(buffer, at: Self.time)
        sink.consume(buffer, at: Self.time)

        #expect(sink.hasAudio)
        #expect(starts.withLock { $0 } == 1)
    }

    @Test
    func `covers the time until the end of the last buffer`() throws {
        let first = try AVAudioPCMBuffer.constant(levels: [0.4], seconds: 0.1, sampleRate: SpeechAudio.sampleRate)
        let last = try AVAudioPCMBuffer.constant(levels: [0.4], seconds: 0.05, sampleRate: SpeechAudio.sampleRate)
        let sink = try #require(AudioSampleSink(inputFormat: first.format, meter: LevelMeter()) {})

        sink.consume(first, at: Self.time)
        sink.consume(last, at: AVAudioTime(hostTime: AVAudioTime.hostTime(forSeconds: 100.1)))

        #expect(abs(sink.coveredUntil - 100.15) < 0.000_001)
    }

    @Test
    func `meters the level of the latest buffer`() throws {
        let meter = LevelMeter()
        let loud = try AVAudioPCMBuffer.constant(levels: [0.5], seconds: 0.1, sampleRate: SpeechAudio.sampleRate)
        let silent = try AVAudioPCMBuffer.constant(levels: [0], seconds: 0.1, sampleRate: SpeechAudio.sampleRate)
        let sink = try #require(AudioSampleSink(inputFormat: loud.format, meter: meter) {})

        sink.consume(loud, at: Self.time)
        let loudLevel = meter.value
        sink.consume(silent, at: Self.time)

        #expect(loudLevel == AudioLevel.meterValue(rootMeanSquare: 0.5))
        #expect(meter.value == 0)
    }
}
