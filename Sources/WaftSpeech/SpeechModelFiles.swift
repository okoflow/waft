import Foundation
import WaftCore

struct SpeechModelFiles {
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

    private static var tokenizerFolder: URL {
        baseDirectory.appending(path: "models/openai/whisper-large-v3", directoryHint: .isDirectory)
    }

    private static var hasTokenizer: Bool {
        FileManager.default.fileExists(atPath: tokenizerFolder.appending(path: "tokenizer.json").path)
    }

    let variant: String

    var folder: URL {
        Self.baseDirectory.appending(path: "models/\(Self.repository)/\(variant)", directoryHint: .isDirectory)
    }

    var isInstalled: Bool {
        guard hasEveryPart, Self.hasTokenizer else { return false }

        return !hasIncompleteDownload
    }

    private var hasEveryPart: Bool {
        Self.requiredParts.allSatisfy { FileManager.default.fileExists(atPath: folder.appending(path: $0).path) }
    }

    private var downloadCache: URL {
        folder.deletingLastPathComponent().appending(path: ".cache/huggingface/download/\(variant)", directoryHint: .isDirectory)
    }

    private var hasIncompleteDownload: Bool {
        guard let pending = try? FileManager.default.subpathsOfDirectory(atPath: downloadCache.path) else { return false }

        return pending.contains { $0.hasSuffix(".incomplete") }
    }

    private var isPresent: Bool {
        FileManager.default.fileExists(atPath: folder.path) || FileManager.default.fileExists(atPath: downloadCache.path)
    }

    init(_ model: SpeechModel) {
        switch model {
        case .fast: variant = "openai_whisper-large-v3-v20240930_626MB"
        case .accurate: variant = "openai_whisper-large-v3"
        }
    }

    private static func removeIfPresent(_ url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        try FileManager.default.removeItem(at: url)
    }

    func markComplete() throws {
        try Data().write(to: folder.appending(path: Self.completionMarker))
        try Self.removeIfPresent(downloadCache)
    }

    func remove() throws {
        try Self.removeIfPresent(folder)
        try Self.removeIfPresent(downloadCache)

        guard !SpeechModel.allCases.map(SpeechModelFiles.init).contains(where: \.isPresent) else { return }

        try Self.removeIfPresent(Self.tokenizerFolder)
    }
}
