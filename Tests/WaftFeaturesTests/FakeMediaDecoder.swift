import Foundation
import os
import WaftCore

final nonisolated class FakeMediaDecoder: MediaDecoder {
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
