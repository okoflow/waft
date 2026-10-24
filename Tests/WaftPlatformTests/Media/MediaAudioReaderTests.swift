import AVFoundation
import Testing
import WaftPlatform

struct MediaAudioReaderTests {
    @Test(arguments: [[0.25], [0.25, 0.25]] as [[Float]])
    func `reads a file as 16 kHz mono floats`(channelLevels: [Float]) async throws {
        try await FileManager.withTemporaryDirectory { directory in
            let url = directory.appending(path: "tone.wav")
            let buffer = try AVAudioPCMBuffer.constant(levels: channelLevels, seconds: 1, sampleRate: 44100)
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: buffer.format.sampleRate,
                AVNumberOfChannelsKey: buffer.format.channelCount,
            ]

            try AVAudioFile(forWriting: url, settings: settings).write(from: buffer)

            let samples = try await MediaAudioReader().samples(of: url)
            let middle = try #require(samples.dropFirst(samples.count / 2).first)

            #expect((15900 ... 16000).contains(samples.count))
            #expect((0.2 ... 0.4).contains(middle))
        }
    }
}
