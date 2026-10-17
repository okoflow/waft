import Foundation
import os
import Testing
import WaftCore
@testable import WaftFeatures

struct FileTranscriptionModelTests {
    private nonisolated static let failure = CocoaError(.fileReadCorruptFile)
    private static let file = URL(filePath: "/tmp/Interview.m4a")

    private static let transcript = TimedTranscript(
        language: .english,
        segments: [TimedSegment(start: 0, end: 2, text: "Hello world.")],
    )

    private let settings = SettingsModel.inMemory()
    private let clipboard = FakeClipboard()

    @Test
    func `transcribes a file and reports progress until it finishes`() async {
        let transcriber = FakeTranscriber(file: .success(Self.transcript), holdsRequests: true)
        let transcription = await model(transcriber)
        transcription.transcribe(Self.file)

        #expect(transcription.phase == .reading(Self.file))
        #expect(await Poll.until(timeout: .seconds(5)) { transcription.phase == .transcribing(Self.file, 0.5) })

        transcriber.release()

        #expect(await Poll.until(timeout: .seconds(5)) { transcription.phase == .finished(Self.file, Self.transcript) })
    }

    @Test
    func `reports a file without speech`() async {
        let transcription = await model(FakeTranscriber(file: .success(nil)))
        transcription.transcribe(Self.file)

        #expect(await Poll.until(timeout: .seconds(5)) {
            transcription.phase == .failed(Self.file, "There's no speech in this file.")
        })
    }

    @Test(arguments: [
        (.failure(failure), .success(nil)),
        (.success([0]), .failure(failure)),
    ] as [(Result<[Float], any Error>, Result<TimedTranscript?, any Error>)])
    func `reports a decoding or transcription failure with the error's description`(
        samples: Result<[Float], any Error>,
        reply: Result<TimedTranscript?, any Error>,
    ) async {
        let transcription = await model(FakeTranscriber(file: reply), decoder: FakeMediaDecoder(decoded: samples))
        transcription.transcribe(Self.file)

        #expect(await Poll.until(timeout: .seconds(5)) {
            transcription.phase == .failed(Self.file, Self.failure.localizedDescription)
        })
    }

    @Test
    func `refuses a file while the speech model is not ready, showing its message`() async throws {
        let message = try #require(SpeechModelState().notReadyMessage)
        let transcriber = FakeTranscriber(file: .success(Self.transcript))
        let transcription = await model(transcriber, isSpeechModelReady: false)
        transcription.transcribe(Self.file)

        #expect(transcription.phase == .failed(Self.file, message))
        #expect(transcriber.requests.isEmpty)
    }

    @Test(arguments: [(false, false), (false, true), (true, false), (true, true)])
    func `stops canceled decoding before it can start transcription`(resets: Bool, beginsDecoding: Bool) async throws {
        let decoder = FakeMediaDecoder(holding: beginsDecoding ? Self.file : nil)
        let transcriber = FakeTranscriber(file: .success(Self.transcript))
        let transcription = await model(transcriber, decoder: decoder)
        transcription.transcribe(Self.file)
        let canceled = try #require(transcription.task)

        if beginsDecoding {
            await decoder.waitUntilReading()
        }

        if resets {
            transcription.reset()
        } else {
            transcription.cancel()
        }

        decoder.release()
        await canceled.value

        #expect(transcription.phase == .idle)
        #expect(decoder.requests == (beginsDecoding ? [Self.file] : []))
        #expect(transcriber.requests.isEmpty)
    }

    @Test
    func `transcribes only the replacement when a file changes during decoding`() async throws {
        let replacement = URL(filePath: "/tmp/Replacement.m4a")
        let decoder = FakeMediaDecoder(holding: Self.file)
        let transcriber = FakeTranscriber(file: .success(Self.transcript))
        let transcription = await model(transcriber, decoder: decoder)
        transcription.transcribe(Self.file)
        let canceled = try #require(transcription.task)
        await decoder.waitUntilReading()

        transcription.transcribe(replacement)
        let current = try #require(transcription.task)
        await current.value

        decoder.release()
        await canceled.value

        #expect(transcription.phase == .finished(replacement, Self.transcript))
        #expect(decoder.requests == [Self.file, replacement])
        #expect(transcriber.requests.count == 1)
    }

    @Test(arguments: [(Language.german, Language?.some(.german)), (.french, nil)])
    func `transcribes in the chosen language only while it is one of the dictation languages`(
        chosen: Language,
        language: Language?,
    ) async {
        settings.settings.languages = .preferred(by: ["de"])
        let transcriber = FakeTranscriber(file: .success(Self.transcript))
        let transcription = await model(transcriber)
        transcription.language = chosen
        transcription.transcribe(Self.file)

        #expect(transcription.language == language)
        #expect(await Poll.until(timeout: .seconds(5)) { !transcriber.requests.isEmpty })
        #expect(transcriber.requests.map(\.language) == [language])
    }

    @Test
    func `copies a finished transcript and marks its file as copied`() async {
        let transcription = await model(FakeTranscriber(file: .success(Self.transcript)))
        transcription.copyText()

        #expect(clipboard.copied.isEmpty)

        transcription.transcribe(Self.file)

        #expect(await Poll.until(timeout: .seconds(5)) { transcription.phase == .finished(Self.file, Self.transcript) })

        transcription.copyText()

        #expect(clipboard.copied == ["Hello world."])
        #expect(transcription.copyFeedback.isShowing(Self.file))
    }

    @Test
    func `accepts no files while one is being read or transcribed`() async {
        let transcriber = FakeTranscriber(file: .success(Self.transcript), holdsRequests: true)
        let transcription = await model(transcriber)

        #expect(transcription.acceptsFiles)

        transcription.transcribe(Self.file)

        #expect(!transcription.acceptsFiles)

        transcriber.release()

        #expect(await Poll.until(timeout: .seconds(5)) { transcription.acceptsFiles })
    }

    @Test(.enabled(if: !ProAccess.isFreeDuringBeta))
    func `ignores files without Pro`() async {
        let transcription = await model(
            FakeTranscriber(file: .success(Self.transcript)),
            pro: .unlicensed(trialStarted: .distantPast),
        )

        transcription.transcribe(Self.file)

        #expect(transcription.phase == .idle)
        #expect(!transcription.acceptsFiles)
    }

    private func model(
        _ transcriber: FakeTranscriber,
        decoder: FakeMediaDecoder = FakeMediaDecoder(),
        isSpeechModelReady: Bool = true,
        pro: ProModel = .unlicensed(),
    ) async -> FileTranscriptionModel {
        let speechModelController = isSpeechModelReady
            ? await SpeechModelController.ready(settings: settings)
            : SpeechModelController(transcriber: transcriber, settings: settings, pro: pro)

        return FileTranscriptionModel(
            transcriber: transcriber,
            decoder: decoder,
            speechModelController: speechModelController,
            settings: settings,
            pro: pro,
            clipboard: clipboard,
        )
    }
}

private final nonisolated class FakeMediaDecoder: MediaDecoder {
    private let decoded: Result<[Float], any Error>
    private let heldFile: URL?
    private let readings: AsyncStream<Void>
    private let readingContinuation: AsyncStream<Void>.Continuation
    private let pendingRelease = OSAllocatedUnfairLock<CheckedContinuation<Void, Never>?>(initialState: nil)
    private let requestedFiles = OSAllocatedUnfairLock(initialState: [URL]())

    var requests: [URL] {
        requestedFiles.withLock { $0 }
    }

    init(decoded: Result<[Float], any Error> = .success([0]), holding heldFile: URL? = nil) {
        self.decoded = decoded
        self.heldFile = heldFile
        (readings, readingContinuation) = AsyncStream.makeStream(of: Void.self)
    }

    func release() {
        let continuation = pendingRelease.withLock { pending in
            let continuation = pending
            pending = nil

            return continuation
        }

        continuation?.resume()
    }

    func waitUntilReading() async {
        var iterator = readings.makeAsyncIterator()
        _ = await iterator.next()
    }

    func samples(of file: URL) async throws -> [Float] {
        requestedFiles.withLock { $0.append(file) }

        if file == heldFile {
            await withCheckedContinuation { continuation in
                pendingRelease.withLock { $0 = continuation }
                readingContinuation.yield(())
            }
        }

        return try decoded.get()
    }
}
