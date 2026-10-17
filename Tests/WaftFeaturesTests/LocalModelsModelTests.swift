import os
import Testing
import WaftCore
@testable import WaftFeatures

struct LocalModelsModelTests {
    private nonisolated static let ollama = "http://localhost:11434/v1"
    private static let lmStudio = "http://localhost:1234/v1"

    private let settings = SettingsModel.inMemory()

    @Test(arguments: [
        ([ollama: ["qwen3", "gemma3"]], LocalModelsModel.ServerState.running, ["qwen3", "gemma3"]),
        ([:], .notRunning, []),
    ])
    func `reports whether the configured server runs and lists its models`(
        served: [String: [String]],
        state: LocalModelsModel.ServerState,
        models: [String],
    ) async {
        let localModels = LocalModelsModel(browser: FakeLocalServerBrowser(served), settings: settings)
        localModels.refresh()

        #expect(localModels.serverState == .checking)
        #expect(await Poll.until(timeout: .seconds(5)) { localModels.serverState == state })
        #expect(localModels.serverModels == models)
    }

    @Test
    func `detects the first known server that answers and selects its first model`() async {
        let browser = FakeLocalServerBrowser([Self.lmStudio: ["qwen3", "gemma3"], "http://localhost:8080/v1": ["llama"]])
        let localModels = LocalModelsModel(browser: browser, settings: settings)
        localModels.detect()

        #expect(await Poll.until(timeout: .seconds(5)) { localModels.serverState == .running })
        #expect(settings.settings.localServer == LocalServer(baseURL: Self.lmStudio, model: "qwen3"))
        #expect(localModels.serverModels == ["qwen3", "gemma3"])
        #expect(browser.answered == [Self.ollama, Self.lmStudio])
    }

    @Test
    func `shows no server running when none of the known servers answers`() async {
        let browser = FakeLocalServerBrowser([:])
        let localModels = LocalModelsModel(browser: browser, settings: settings)
        localModels.detect()

        #expect(await Poll.until(timeout: .seconds(5)) { localModels.serverState == .notRunning })
        #expect(browser.answered == LocalServer.knownServers.map(\.baseURL))
        #expect(settings.settings.localServer == LocalServer())
    }

    @Test
    func `ignores the result of a check that a newer one replaced`() async throws {
        let browser = FakeLocalServerBrowser([Self.ollama: ["stale"], Self.lmStudio: ["qwen3"]], holding: Self.ollama)
        let localModels = LocalModelsModel(browser: browser, settings: settings)
        localModels.refresh()
        let canceled = try #require(localModels.check)
        await browser.waitUntilAsked()

        settings.settings.localServer = LocalServer(baseURL: Self.lmStudio)
        localModels.refresh()
        let current = try #require(localModels.check)
        await current.value

        browser.release()
        await canceled.value

        #expect(browser.answered == [Self.lmStudio, Self.ollama])
        #expect(localModels.serverModels == ["qwen3"])
    }

    @Test
    func `stops detecting servers after a superseded probe fails`() async throws {
        let browser = FakeLocalServerBrowser([Self.lmStudio: ["qwen3"]], holding: Self.ollama)
        let localModels = LocalModelsModel(browser: browser, settings: settings)
        localModels.detect()
        let canceled = try #require(localModels.check)
        await browser.waitUntilAsked()

        settings.settings.localServer = LocalServer(baseURL: Self.lmStudio)
        localModels.refresh()
        let current = try #require(localModels.check)
        await current.value

        browser.release()
        await canceled.value

        #expect(browser.answered == [Self.lmStudio, Self.ollama])
        #expect(localModels.serverState == .running)
        #expect(localModels.serverModels == ["qwen3"])
        #expect(settings.settings.localServer == LocalServer(baseURL: Self.lmStudio))
    }

    @Test(arguments: [false, true])
    func `makes no requests for a check canceled before it starts`(detects: Bool) async throws {
        let browser = FakeLocalServerBrowser([Self.lmStudio: ["qwen3"]])
        let localModels = LocalModelsModel(browser: browser, settings: settings)

        if detects {
            localModels.detect()
        } else {
            localModels.refresh()
        }

        let canceled = try #require(localModels.check)
        settings.settings.localServer = LocalServer(baseURL: Self.lmStudio)
        localModels.refresh()
        let current = try #require(localModels.check)

        await canceled.value
        await current.value

        #expect(browser.answered == [Self.lmStudio])
        #expect(localModels.serverModels == ["qwen3"])
    }
}

private final nonisolated class FakeLocalServerBrowser: LocalServerBrowsing {
    private let served: [String: [String]]
    private let heldURL: String?
    private let queries: AsyncStream<Void>
    private let queryContinuation: AsyncStream<Void>.Continuation
    private let pendingRelease = OSAllocatedUnfairLock<CheckedContinuation<Void, Never>?>(initialState: nil)
    private let answeredURLs = OSAllocatedUnfairLock(initialState: [String]())

    var answered: [String] {
        answeredURLs.withLock { $0 }
    }

    init(_ served: [String: [String]], holding heldURL: String? = nil) {
        self.served = served
        self.heldURL = heldURL
        (queries, queryContinuation) = AsyncStream.makeStream(of: Void.self)
    }

    func release() {
        let continuation = pendingRelease.withLock { pending in
            let continuation = pending
            pending = nil

            return continuation
        }

        continuation?.resume()
    }

    func waitUntilAsked() async {
        var iterator = queries.makeAsyncIterator()
        _ = await iterator.next()
    }

    func models(at server: LocalServer) async throws(RewriteError) -> [String] {
        if server.baseURL == heldURL {
            await withCheckedContinuation { continuation in
                pendingRelease.withLock { $0 = continuation }
                queryContinuation.yield(())
            }
        }

        answeredURLs.withLock { $0.append(server.baseURL) }

        guard let models = served[server.baseURL] else { throw .offline }

        return models
    }
}
