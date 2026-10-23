import Foundation
import os
import WaftCore

struct SpeechModelFiles {
    static let repository = "argmaxinc/whisperkit-coreml"
    static let defaultBaseDirectory = AppIdentity.supportDirectory.appending(path: "Models", directoryHint: .isDirectory)

    private static let completionMarker = ".waft-complete"

    private static let requiredParts = [
        completionMarker,
        "AudioEncoder.mlmodelc",
        "MelSpectrogram.mlmodelc",
        "TextDecoder.mlmodelc",
        "config.json",
    ]

    let variant: String
    let baseDirectory: URL

    private let readSubpaths: @Sendable (URL) throws -> [String]

    var folder: URL {
        baseDirectory.appending(path: "models/\(Self.repository)/\(variant)", directoryHint: .isDirectory)
    }

    var isInstalled: Bool {
        guard hasEveryPart, hasTokenizer else { return false }

        return !hasIncompleteDownload
    }

    private var hasEveryPart: Bool {
        Self.requiredParts.allSatisfy { FileManager.default.fileExists(atPath: folder.appending(path: $0).path) }
    }

    private var downloadCache: URL {
        folder.deletingLastPathComponent().appending(path: ".cache/huggingface/download/\(variant)", directoryHint: .isDirectory)
    }

    private var hasIncompleteDownload: Bool {
        do {
            let pending = try readSubpaths(downloadCache)

            return pending.contains { $0.hasSuffix(".incomplete") }
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return false
        } catch {
            Logger.speech.error("Couldn't inspect the speech model download: \(error.logDescription, privacy: .public)")

            return true
        }
    }

    private var isPresent: Bool {
        [folder, downloadCache].contains { FileManager.default.fileExists(atPath: $0.path) }
    }

    private var tokenizerFolder: URL {
        baseDirectory.appending(path: "models/openai/whisper-large-v3", directoryHint: .isDirectory)
    }

    private var hasTokenizer: Bool {
        FileManager.default.fileExists(atPath: tokenizerFolder.appending(path: "tokenizer.json").path)
    }

    init(
        _ model: SpeechModel,
        baseDirectory: URL = Self.defaultBaseDirectory,
        readSubpaths: @escaping @Sendable (URL) throws -> [String] = { directory in
            try FileManager.default.subpathsOfDirectory(atPath: directory.path)
        },
    ) {
        switch model {
        case .fast: variant = "openai_whisper-large-v3-v20240930_626MB"
        case .accurate: variant = "openai_whisper-large-v3"
        }

        self.baseDirectory = baseDirectory
        self.readSubpaths = readSubpaths
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

        let modelFiles = SpeechModel.allCases.map { SpeechModelFiles($0, baseDirectory: baseDirectory) }
        guard !modelFiles.contains(where: \.isPresent) else { return }

        try Self.removeIfPresent(tokenizerFolder)
    }
}
