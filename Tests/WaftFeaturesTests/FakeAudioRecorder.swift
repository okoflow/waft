import Foundation
import os
import WaftCore

final nonisolated class FakeAudioRecorder: AudioRecorder {
    private struct State {
        var startedDevices: [String?] = []
        var releaseTimes: [TimeInterval?] = []
    }

    let events: AsyncStream<RecordingEvent>
    let inputLevel: Float = 0

    private let continuation: AsyncStream<RecordingEvent>.Continuation
    private let samples: [Float]
    private let failure: RecordingFailure?
    private let state = OSAllocatedUnfairLock(initialState: State())

    var startedDevices: [String?] {
        state.withLock { $0.startedDevices }
    }

    var releaseTimes: [TimeInterval?] {
        state.withLock { $0.releaseTimes }
    }

    init(samples: [Float] = [0.1, 0.2], failure: RecordingFailure? = nil) {
        let (events, continuation) = AsyncStream.makeStream(of: RecordingEvent.self)

        self.events = events
        self.continuation = continuation
        self.samples = samples
        self.failure = failure
    }

    func send(_ event: RecordingEvent) {
        continuation.yield(event)
    }

    func start(_: RecordingID, deviceID: String?) {
        state.withLock { $0.startedDevices.append(deviceID) }
    }

    func stop(_: RecordingID, releasedAt: TimeInterval?) -> [Float] {
        state.withLock { $0.releaseTimes.append(releasedAt) }

        return samples
    }

    func failure(for _: RecordingID) -> RecordingFailure? {
        failure
    }
}
