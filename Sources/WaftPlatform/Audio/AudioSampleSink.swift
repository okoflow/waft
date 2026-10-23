import AVFoundation
import os
import WaftCore

final class AudioSampleSink: @unchecked Sendable {
    private struct Captured {
        var samples: [Float] = []
        var hasAudio = false
        var coveredUntil: TimeInterval = 0
        var hasLoggedFailure = false
    }

    private final class PendingInput: @unchecked Sendable {
        private var buffer: AVAudioPCMBuffer?

        init(_ buffer: AVAudioPCMBuffer) {
            self.buffer = buffer
        }

        func take() -> AVAudioPCMBuffer? {
            let taken = buffer
            buffer = nil

            return taken
        }
    }

    private let converter: AVAudioConverter
    private let outputFormat: AVAudioFormat
    private let inputSampleRate: Double
    private let meter: LevelMeter
    private let onFirstBuffer: @Sendable () -> Void
    private let captured = OSAllocatedUnfairLock(initialState: Captured())

    var hasAudio: Bool {
        captured.withLock { $0.hasAudio }
    }

    var coveredUntil: TimeInterval {
        captured.withLock { $0.coveredUntil }
    }

    var samples: [Float] {
        captured.withLock { $0.samples }
    }

    init?(inputFormat: AVAudioFormat, meter: LevelMeter, onFirstBuffer: @escaping @Sendable () -> Void) {
        guard let outputFormat = AVAudioFormat(
                  commonFormat: .pcmFormatFloat32,
                  sampleRate: SpeechAudio.sampleRate,
                  channels: 1,
                  interleaved: false,
              ),
              let converter = AVAudioConverter(from: inputFormat, to: outputFormat)
        else { return nil }

        converter.downmix = true

        self.converter = converter
        self.outputFormat = outputFormat
        inputSampleRate = inputFormat.sampleRate
        self.meter = meter
        self.onFirstBuffer = onFirstBuffer
    }

    func consume(_ input: AVAudioPCMBuffer, at time: AVAudioTime) {
        let start = time.isHostTimeValid ? AVAudioTime.seconds(forHostTime: time.hostTime) : Uptime.now
        let end = start + Double(input.frameLength) / inputSampleRate
        let converted = convert(input)
        guard !converted.isEmpty else { return }

        meter.value = AudioLevel.meterValue(rootMeanSquare: AudioLevel.rootMeanSquare(converted))

        let isFirstBuffer = captured.withLock { captured in
            let isFirst = !captured.hasAudio
            captured.hasAudio = true
            captured.samples.append(contentsOf: converted)
            captured.coveredUntil = end

            return isFirst
        }

        if isFirstBuffer {
            onFirstBuffer()
        }
    }

    private func convert(_ input: AVAudioPCMBuffer) -> [Float] {
        let capacity = AVAudioFrameCount((Double(input.frameLength) * SpeechAudio.sampleRate / inputSampleRate).rounded(.up)) + 32
        guard let output = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity) else {
            logFirstFailure {
                Logger.audio.error("Couldn't allocate a buffer of \(capacity, privacy: .public) frames for the input audio")
            }

            return []
        }

        let pending = PendingInput(input)
        var error: NSError?

        converter.convert(to: output, error: &error) { _, status in
            guard let buffer = pending.take() else {
                status.pointee = .noDataNow

                return nil
            }

            status.pointee = .haveData

            return buffer
        }

        if let error {
            logFirstFailure {
                Logger.audio.error("Couldn't convert audio: \(error.domain, privacy: .public) \(error.code, privacy: .public)")
            }

            return []
        }

        guard output.frameLength > 0, let channel = output.floatChannelData?[0] else { return [] }

        return Array(UnsafeBufferPointer(start: channel, count: Int(output.frameLength)))
    }

    private func logFirstFailure(_ log: () -> Void) {
        let isFirst = captured.withLock { captured in
            let isFirst = !captured.hasLoggedFailure
            captured.hasLoggedFailure = true

            return isFirst
        }

        guard isFirst else { return }

        log()
    }
}
