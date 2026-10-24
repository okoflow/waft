package import Foundation
import AVFoundation
import os
import WaftCore

package actor MediaAudioReader: MediaDecoder {
    private let queue = DispatchSerialQueue(label: "\(AppIdentity.bundleIdentifier).media")

    package nonisolated var unownedExecutor: UnownedSerialExecutor {
        queue.asUnownedSerialExecutor()
    }

    package init() {}

    private static func append(_ buffer: CMSampleBuffer, to samples: inout [Float]) throws(MediaAudioError) {
        guard let block = CMSampleBufferGetDataBuffer(buffer) else {
            Logger.audio.error("A sample buffer of the file has no data")

            throw .unreadable
        }

        let count = CMBlockBufferGetDataLength(block) / MemoryLayout<Float>.size
        let start = samples.count

        samples.append(contentsOf: repeatElement(0, count: count))

        let status = samples.withUnsafeMutableBytes { bytes in
            guard let base = bytes.baseAddress else { return kCMBlockBufferNoErr }

            return CMBlockBufferCopyDataBytes(
                block,
                atOffset: 0,
                dataLength: count * MemoryLayout<Float>.size,
                destination: base + start * MemoryLayout<Float>.size,
            )
        }

        guard status == kCMBlockBufferNoErr else {
            Logger.audio.error("Couldn't copy the file's audio: OSStatus \(status, privacy: .public)")

            throw .unreadable
        }
    }

    private static func failure(of reader: AVAssetReader) -> MediaAudioError {
        if let error = reader.error as NSError? {
            Logger.audio.error(
                """
                Couldn't read the file's audio: \(error.domain, privacy: .public) \(error.code, privacy: .public) \
                \(error.localizedDescription, privacy: .private)
                """,
            )
        }

        return .unreadable
    }

    package func samples(of url: URL) async throws -> [Float] {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .audio).first else { throw MediaAudioError.noAudio }

        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: SpeechAudio.sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsNonInterleaved: false,
            AVLinearPCMIsBigEndianKey: false,
        ])

        output.alwaysCopiesSampleData = false
        reader.add(output)

        guard reader.startReading() else { throw Self.failure(of: reader) }

        var samples: [Float] = []

        while let buffer = output.copyNextSampleBuffer() {
            try Task.checkCancellation()
            try Self.append(buffer, to: &samples)
        }

        guard reader.status == .completed else { throw Self.failure(of: reader) }

        return samples
    }
}
