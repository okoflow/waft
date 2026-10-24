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

    @Test(arguments: [(String?.none, true), ("config.json.metadata", true), ("AudioEncoder.mlmodelc.incomplete", false)])
    func `counts a complete model as installed unless its download is incomplete`(cacheFile: String?, isInstalled: Bool) throws {
        try withTemporaryDirectory { directory in
            let accurate = try installed(.accurate, in: directory)

            if let cacheFile {
                let cache = downloadCache(for: accurate)

                try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
                try Data().write(to: cache.appending(path: cacheFile))
            }

            #expect(accurate.isInstalled == isInstalled)
        }
    }

    @Test(arguments: [CocoaError.Code.fileReadNoPermission, .fileReadUnknown])
    func `counts a model with unreadable download metadata as not installed`(failure: CocoaError.Code) throws {
        try withTemporaryDirectory { directory in
            let accurate = try installed(.accurate, in: directory)

            #expect(accurate.isInstalled)

            let unreadable = SpeechModelFiles(.accurate, baseDirectory: directory) { _ in
                throw CocoaError(failure)
            }

            #expect(!unreadable.isInstalled)
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

    private func downloadCache(for files: SpeechModelFiles) -> URL {
        files.folder.deletingLastPathComponent()
            .appending(path: ".cache/huggingface/download/\(files.variant)", directoryHint: .isDirectory)
    }
}
