import Foundation
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

    @Test
    func `ignores the result of a canceled transcription`() async {
        let transcriber = FakeTranscriber(file: .success(Self.transcript))
        let transcription = await model(transcriber, decoder: FakeMediaDecoder(holdsUntilCanceled: true))
        transcription.transcribe(Self.file)
        transcription.cancel()

        #expect(transcription.phase == .idle)
        #expect(await Poll.until(timeout: .seconds(5)) { !transcriber.requests.isEmpty })
        #expect(transcription.phase == .idle)
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
        let speechModel = isSpeechModelReady
            ? await SpeechModelController.ready(settings: settings)
            : SpeechModelController(transcriber: transcriber, settings: settings, pro: pro)

        return FileTranscriptionModel(
            transcriber: transcriber,
            decoder: decoder,
            speechModel: speechModel,
            settings: settings,
            pro: pro,
            clipboard: clipboard,
        )
    }
}

private nonisolated struct FakeMediaDecoder: MediaDecoder {
    var decoded: Result<[Float], any Error> = .success([0])
    var holdsUntilCanceled = false

    func samples(of _: URL) async throws -> [Float] {
        if holdsUntilCanceled {
            await Task.slept(for: .seconds(60))
        }

        return try decoded.get()
    }
}
