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
    func `ignores the result of a check that a newer one replaced`() async {
        let browser = FakeLocalServerBrowser([Self.ollama: ["stale"], Self.lmStudio: ["qwen3"]], holding: Self.ollama)
        let localModels = LocalModelsModel(browser: browser, settings: settings)
        localModels.refresh()
        settings.settings.localServer = LocalServer(baseURL: Self.lmStudio)
        localModels.refresh()

        #expect(await Poll.until(timeout: .seconds(5)) { localModels.serverModels == ["qwen3"] })

        browser.release()

        #expect(await Poll.until(timeout: .seconds(5)) { browser.answered == [Self.lmStudio, Self.ollama] })
        #expect(localModels.serverModels == ["qwen3"])
    }
}

private final nonisolated class FakeLocalServerBrowser: LocalServerBrowsing {
    private struct State {
        var answered: [String] = []
        var isReleased = false
    }

    private let served: [String: [String]]
    private let heldURL: String?
    private let state = OSAllocatedUnfairLock(initialState: State())

    var answered: [String] {
        state.withLock { $0.answered }
    }

    init(_ served: [String: [String]], holding heldURL: String? = nil) {
        self.served = served
        self.heldURL = heldURL
    }

    func release() {
        state.withLock { $0.isReleased = true }
    }

    func models(at server: LocalServer) async throws(RewriteError) -> [String] {
        let deadline = ContinuousClock.now + .seconds(5)

        while server.baseURL == heldURL, !state.withLock({ $0.isReleased }), ContinuousClock.now < deadline {
            await Task.yield()
        }

        state.withLock { $0.answered.append(server.baseURL) }

        guard let models = served[server.baseURL] else { throw .offline }

        return models
    }
}
