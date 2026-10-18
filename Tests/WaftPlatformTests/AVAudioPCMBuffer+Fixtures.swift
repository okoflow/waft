import AVFoundation
import Testing

extension AVAudioPCMBuffer {
    static func constant(levels: [Float], seconds: Double, sampleRate: Double) throws -> AVAudioPCMBuffer {
        let channelCount = AVAudioChannelCount(levels.count)
        let frameCount = AVAudioFrameCount(sampleRate * seconds)
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channelCount))
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount))
        let channels = try #require(buffer.floatChannelData)

        buffer.frameLength = frameCount

        for (channel, level) in levels.enumerated() {
            channels[channel].update(repeating: level, count: Int(frameCount))
        }

        return buffer
    }
}
