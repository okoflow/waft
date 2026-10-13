import Foundation
import os
import WaftCore

final nonisolated class FakeTranscriber: Transcriber {
    struct Request: Equatable {
        let language: Language?
        let vocabulary: [String]
    }

    private struct State {
        var requests: [Request] = []
        var releases = 0
    }

    let modelDirectory = URL(filePath: "/dev/null")

    private let replies: [Result<Transcript?, any Error>]
    private let fileReply: Result<TimedTranscript?, any Error>
    private let holdsRequests: Bool
    private let state = OSAllocatedUnfairLock(initialState: State())

    var requests: [Request] {
        state.withLock { $0.requests }
    }

    init(
        _ replies: Result<Transcript?, any Error>...,
        file fileReply: Result<TimedTranscript?, any Error> = .success(nil),
        holdsRequests: Bool = false,
    ) {
        self.replies = replies
        self.fileReply = fileReply
        self.holdsRequests = holdsRequests
    }

    func release() {
        state.withLock { $0.releases += 1 }
    }

    func isModelInstalled() -> Bool {
        true
    }

    func downloadModel(progress _: @Sendable (Double) -> Void) {}

    func loadModel(for _: [Language]) -> Duration {
        .zero
    }

    func deleteModel() {}

    func transcribe(_: [Float], in language: Language?, vocabulary: [String]) async throws -> Transcript? {
        let number = await answer(Request(language: language, vocabulary: vocabulary))
        guard let reply = replies.dropFirst(number - 1).first else { return nil }

        return try reply.get()
    }

    func transcribeFile(
        _: [Float],
        in language: Language?,
        progress: @Sendable (Double) -> Void,
    ) async throws -> TimedTranscript? {
        progress(0.5)

        _ = await answer(Request(language: language, vocabulary: []))

        return try fileReply.get()
    }

    private func answer(_ request: Request) async -> Int {
        let number = state.withLock { state in
            state.requests.append(request)

            return state.requests.count
        }

        if holdsRequests {
            await Poll.until(timeout: .seconds(5)) { state.withLock { $0.releases >= number } }
        }

        return number
    }
}
