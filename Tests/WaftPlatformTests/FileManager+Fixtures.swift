import Foundation

extension FileManager {
    static func withTemporaryDirectory(_ body: (URL) async throws -> Void) async throws {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "WaftTests-\(UUID().uuidString)",
            directoryHint: .isDirectory,
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        do {
            try await body(directory)
        } catch {
            try FileManager.default.removeItem(at: directory)

            throw error
        }

        try FileManager.default.removeItem(at: directory)
    }
}
