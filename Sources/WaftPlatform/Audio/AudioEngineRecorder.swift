package import Foundation
package import WaftCore
import AVFoundation
import os

package actor AudioEngineRecorder: AudioRecorder {
    private struct Session {
        let recording: RecordingID
        let engine: AVAudioEngine
        let sink: AudioSampleSink
        let configurationObserver: any NSObjectProtocol
        let sampleRate: Double
        let channelCount: AVAudioChannelCount
    }

    private static let tailGrace = Duration.milliseconds(150)

    package nonisolated let events: AsyncStream<RecordingEvent>

    private nonisolated let continuation: AsyncStream<RecordingEvent>.Continuation
    private nonisolated let meter = LevelMeter()
    private let queue = DispatchSerialQueue(label: "\(AppIdentity.bundleIdentifier).recorder")
    private var session: Session?
    private var stoppedThrough = RecordingID.none
    private var lastFailure: (recording: RecordingID, failure: RecordingFailure)?

    package nonisolated var inputLevel: Float {
        meter.value
    }

    package nonisolated var unownedExecutor: UnownedSerialExecutor {
        queue.asUnownedSerialExecutor()
    }

    package init() {
        let stream = AsyncStream.makeStream(of: RecordingEvent.self)
        events = stream.stream
        continuation = stream.continuation
    }

    private nonisolated static func tapBlock(for sink: AudioSampleSink) -> AVAudioNodeTapBlock {
        { @Sendable buffer, time in
            sink.consume(buffer, at: time)
        }
    }

    package func start(_ recording: RecordingID, deviceID: String?) {
        guard recording > stoppedThrough else { return }

        tearDown()

        do throws(RecordingFailure) {
            session = try makeSession(for: recording, deviceID: deviceID)
        } catch {
            report(error, for: recording)
        }
    }

    package func stop(_ recording: RecordingID, releasedAt: TimeInterval?) async -> [Float] {
        stoppedThrough = max(stoppedThrough, recording)

        guard let current = session, current.recording == recording else { return [] }

        if let releasedAt {
            await waitForTail(of: current.sink, after: releasedAt)
        }

        if session?.recording == recording {
            tearDown()
        }

        return current.sink.samples
    }

    package func failure(for recording: RecordingID) -> RecordingFailure? {
        guard let lastFailure, lastFailure.recording == recording else { return nil }

        return lastFailure.failure
    }

    private func makeSession(for recording: RecordingID, deviceID: String?) throws(RecordingFailure) -> Session {
        let engine = AVAudioEngine()
        let deviceName = try selectInput(deviceID, on: engine)
        let format = engine.inputNode.inputFormat(forBus: 0)
        guard format.channelCount > 0, format.sampleRate > 0 else {
            Logger.audio.error(
                "\(deviceName) reports \(format.channelCount) channels at \(format.sampleRate) Hz",
            )

            throw .noInputChannels
        }

        let continuation = continuation
        let sink = AudioSampleSink(inputFormat: format, meter: meter) {
            continuation.yield(.started(recording, deviceName: deviceName))
        }

        guard let sink else {
            Logger.audio.error("Can't convert the input format of \(format.channelCount) channels at \(format.sampleRate) Hz")

            throw .unsupportedFormat
        }

        engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: format, block: Self.tapBlock(for: sink))
        let observer = observeConfigurationChanges(of: engine, for: recording)

        do {
            try engine.start()
        } catch {
            NotificationCenter.default.removeObserver(observer)
            engine.inputNode.removeTap(onBus: 0)

            let cause = error as NSError

            Logger.audio.error("The audio engine didn't start: \(cause.domain, privacy: .public) \(cause.code, privacy: .public)")

            throw .engineDidNotStart
        }

        return Session(
            recording: recording,
            engine: engine,
            sink: sink,
            configurationObserver: observer,
            sampleRate: format.sampleRate,
            channelCount: format.channelCount,
        )
    }

    private func selectInput(_ deviceID: String?, on engine: AVAudioEngine) throws(RecordingFailure) -> String {
        guard let deviceID else { return CoreAudioInputs.defaultInputName() }
        guard let audioDeviceID = CoreAudioInputs.deviceID(for: deviceID) else {
            Logger.audio.notice("Microphone \(deviceID, privacy: .public) isn't connected; using the default input")

            return CoreAudioInputs.defaultInputName()
        }
        guard let unit = engine.inputNode.audioUnit else {
            Logger.audio.error("No audio unit to select microphone \(deviceID, privacy: .public); using the default input")

            return CoreAudioInputs.defaultInputName()
        }

        var selected = audioDeviceID
        let status = AudioUnitSetProperty(
            unit,
            kAudioOutputUnitProperty_CurrentDevice,
            kAudioUnitScope_Global,
            0,
            &selected,
            UInt32(MemoryLayout<AudioDeviceID>.size),
        )

        guard status == noErr else {
            Logger.audio.error("Couldn't select microphone \(deviceID, privacy: .public): OSStatus \(status, privacy: .public)")

            throw .deviceUnavailable
        }
        guard let name = CoreAudioInputs.name(of: audioDeviceID) else { return deviceID }

        return name
    }

    private func observeConfigurationChanges(of engine: AVAudioEngine, for recording: RecordingID) -> any NSObjectProtocol {
        NotificationCenter.default
            .addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: nil) { [weak self] _ in
                Task { await self?.configurationChanged(for: recording) }
            }
    }

    private func configurationChanged(for recording: RecordingID) async {
        guard let current = session, current.recording == recording else { return }
        guard current.sink.hasAudio else {
            await checkStartup(of: current)

            return
        }

        let format = current.engine.inputNode.inputFormat(forBus: 0)
        let hasFormatChanged = format.sampleRate != current.sampleRate || format.channelCount != current.channelCount

        if !current.engine.isRunning {
            report(.stoppedAfterDeviceChange, for: recording)
        } else if hasFormatChanged {
            report(.formatChanged, for: recording)
        }
    }

    private func checkStartup(of current: Session) async {
        guard !current.engine.isRunning else { return }

        let resumed = await Poll.until(timeout: .milliseconds(200)) { current.sink.hasAudio || current.engine.isRunning }

        if !resumed, session?.recording == current.recording {
            report(.stoppedWhileStarting, for: current.recording)
        }
    }

    private func waitForTail(of sink: AudioSampleSink, after releasedAt: TimeInterval) async {
        await Poll.until(timeout: Self.tailGrace, every: .milliseconds(10)) { sink.coveredUntil >= releasedAt }
    }

    private func report(_ failure: RecordingFailure, for recording: RecordingID) {
        lastFailure = (recording, failure)

        continuation.yield(.failed(recording, failure))

        Logger.audio.error("Recording failed: \(failure.rawValue, privacy: .public)")
    }

    private func tearDown() {
        guard let current = session else { return }

        NotificationCenter.default.removeObserver(current.configurationObserver)
        current.engine.inputNode.removeTap(onBus: 0)
        current.engine.stop()

        session = nil
        meter.value = 0
    }
}
