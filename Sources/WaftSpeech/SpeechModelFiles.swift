import Foundation
import WaftCore

enum SpeechModelFiles {
    static let model = "openai_whisper-large-v3-v20240930_626MB"
    static let repository = "argmaxinc/whisperkit-coreml"
    static let baseDirectory = AppIdentity.supportDirectory.appending(path: "Models", directoryHint: .isDirectory)

    private static let completionMarker = ".waft-complete"

    private static let requiredParts = [
        completionMarker,
        "AudioEncoder.mlmodelc",
        "MelSpectrogram.mlmodelc",
        "TextDecoder.mlmodelc",
        "config.json",
    ]

    static var folder: URL {
        baseDirectory.appending(path: "models/\(repository)/\(model)", directoryHint: .isDirectory)
    }

    static var isInstalled: Bool {
        guard hasEveryPart, hasTokenizer else { return false }

        return !hasIncompleteDownload
    }

    private static var hasEveryPart: Bool {
        requiredParts.allSatisfy { FileManager.default.fileExists(atPath: folder.appending(path: $0).path) }
    }

    private static var hasTokenizer: Bool {
        FileManager.default.fileExists(atPath: tokenizerFolder.appending(path: "tokenizer.json").path)
    }

    private static var tokenizerFolder: URL {
        baseDirectory.appending(path: "models/openai/whisper-large-v3", directoryHint: .isDirectory)
    }

    private static var downloadCache: URL {
        folder.deletingLastPathComponent().appending(path: ".cache/huggingface/download/\(model)", directoryHint: .isDirectory)
    }

    private static var hasIncompleteDownload: Bool {
        guard let pending = try? FileManager.default.subpathsOfDirectory(atPath: downloadCache.path) else { return false }

        return pending.contains { $0.hasSuffix(".incomplete") }
    }

    static func markComplete() throws {
        try Data().write(to: folder.appending(path: completionMarker))
        try removeIfPresent(downloadCache)
    }

    static func remove() throws {
        try removeIfPresent(folder)
        try removeIfPresent(downloadCache)
        try removeIfPresent(tokenizerFolder)
    }

    private static func removeIfPresent(_ url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        try FileManager.default.removeItem(at: url)
    }
}
