import Foundation
import Testing
import WaftCore
@testable import WaftSpeech

struct SpeechModelFilesTests {
    private static let modelParts = ["AudioEncoder.mlmodelc", "MelSpectrogram.mlmodelc", "TextDecoder.mlmodelc", "config.json"]

    @Test
    func `keeps the shared tokenizer while the other model remains`() throws {
        try withTemporaryDirectory { directory in
            let fast = try installed(.fast, in: directory)
            let accurate = try installed(.accurate, in: directory)

            try fast.remove()

            #expect(!fast.isInstalled)
            #expect(accurate.isInstalled)
            #expect(FileManager.default.fileExists(atPath: tokenizerFile(in: directory).path))
        }
    }

    @Test
    func `removes the shared tokenizer with the last model`() throws {
        try withTemporaryDirectory { directory in
            let accurate = try installed(.accurate, in: directory)

            try accurate.remove()

            #expect(!accurate.isInstalled)
            #expect(!FileManager.default.fileExists(atPath: tokenizerFile(in: directory).path))
        }
    }

    @Test
    func `counts a model with an incomplete download as not installed`() throws {
        try withTemporaryDirectory { directory in
            let accurate = try installed(.accurate, in: directory)

            #expect(accurate.isInstalled)

            let pending = accurate.folder.deletingLastPathComponent()
                .appending(path: ".cache/huggingface/download/\(accurate.variant)", directoryHint: .isDirectory)

            try FileManager.default.createDirectory(at: pending, withIntermediateDirectories: true)
            try Data().write(to: pending.appending(path: "AudioEncoder.mlmodelc.incomplete"))

            #expect(!accurate.isInstalled)
        }
    }

    private func withTemporaryDirectory(_ body: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "WaftTests-\(UUID().uuidString)",
            directoryHint: .isDirectory,
        )

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        do {
            try body(directory)
        } catch {
            try FileManager.default.removeItem(at: directory)

            throw error
        }

        try FileManager.default.removeItem(at: directory)
    }

    private func installed(_ model: SpeechModel, in directory: URL) throws -> SpeechModelFiles {
        let files = SpeechModelFiles(model, baseDirectory: directory)
        let tokenizer = tokenizerFile(in: directory)
        try FileManager.default.createDirectory(at: files.folder, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: tokenizer.deletingLastPathComponent(), withIntermediateDirectories: true)

        for part in Self.modelParts {
            try Data().write(to: files.folder.appending(path: part))
        }

        try Data().write(to: tokenizer)
        try files.markComplete()

        return files
    }

    private func tokenizerFile(in directory: URL) -> URL {
        directory.appending(path: "models/openai/whisper-large-v3/tokenizer.json")
    }
}
