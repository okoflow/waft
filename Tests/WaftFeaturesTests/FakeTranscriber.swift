import Foundation
import os
import WaftCore

final nonisolated class FakeTranscriber: Transcriber {
    struct Request: Equatable {
        let language: Language?
        let vocabulary: [String]
    }

    enum Call: Equatable {
        case download(SpeechModel)
        case cancelDownload(SpeechModel)
        case load(SpeechModel)
        case delete(SpeechModel)
    }

    private struct State {
        var installed: Set<SpeechModel>
        var failsDownloads = false
        var calls: [Call] = []
        var requests: [Request] = []
        var releases = 0
    }

    private let replies: [Result<Transcript?, any Error>]
    private let fileReply: Result<TimedTranscript?, any Error>
    private let holdsRequests: Bool
    private let holdsDownloads: Bool
    private let state: OSAllocatedUnfairLock<State>

    var requests: [Request] {
        state.withLock { $0.requests }
    }

    var calls: [Call] {
        state.withLock { $0.calls }
    }

    var failsDownloads: Bool {
        get { state.withLock { $0.failsDownloads } }
        set { state.withLock { $0.failsDownloads = newValue } }
    }

    init(
        _ replies: Result<Transcript?, any Error>...,
        file fileReply: Result<TimedTranscript?, any Error> = .success(nil),
        holdsRequests: Bool = false,
        installed: Set<SpeechModel> = Set(SpeechModel.allCases),
        holdsDownloads: Bool = false,
    ) {
        self.replies = replies
        self.fileReply = fileReply
        self.holdsRequests = holdsRequests
        self.holdsDownloads = holdsDownloads
        state = OSAllocatedUnfairLock(initialState: State(installed: installed))
    }

    func release() {
        state.withLock { $0.releases += 1 }
    }

    func modelDirectory(for model: SpeechModel) -> URL {
        URL(filePath: NSTemporaryDirectory()).appending(path: model.rawValue)
    }

    func isModelInstalled(_ model: SpeechModel) -> Bool {
        state.withLock { $0.installed.contains(model) }
    }

    func downloadModel(_ model: SpeechModel, progress _: @Sendable (Double) -> Void) async throws {
        let fails = state.withLock { state in
            state.calls.append(.download(model))

            return state.failsDownloads
        }

        guard !fails else { throw URLError(.notConnectedToInternet) }

        if holdsDownloads {
            do {
                try await Task.sleep(for: .seconds(60))
            } catch {
                state.withLock { $0.calls.append(.cancelDownload(model)) }

                throw error
            }
        }

        state.withLock { _ = $0.installed.insert(model) }
    }

    func loadModel(_ model: SpeechModel, for _: [Language]) -> Duration {
        state.withLock { $0.calls.append(.load(model)) }

        return .zero
    }

    func deleteModel(_ model: SpeechModel) {
        state.withLock { state in
            state.calls.append(.delete(model))
            state.installed.remove(model)
        }
    }

    func transcribe(
        _: [Float],
        in language: Language?,
        writing _: WritingVariants,
        vocabulary: [String],
    ) async throws -> Transcript? {
        let number = await answer(Request(language: language, vocabulary: vocabulary))
        guard let reply = replies.dropFirst(number - 1).first else { return nil }

        return try reply.get()
    }

    func transcribeFile(
        _: [Float],
        in language: Language?,
        writing _: WritingVariants,
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
