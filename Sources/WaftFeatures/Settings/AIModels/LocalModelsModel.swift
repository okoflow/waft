import Observation
import WaftCore

@Observable
final class LocalModelsModel {
    enum ServerState: Equatable {
        case unknown
        case checking
        case running
        case notRunning
    }

    private(set) var serverState = ServerState.unknown
    private(set) var serverModels: [String] = []

    @ObservationIgnored private(set) var check: Task<Void, Never>?

    @ObservationIgnored private var checkedAddress: String?

    private let browser: any LocalServerBrowsing
    private let settings: SettingsModel

    init(browser: any LocalServerBrowsing, settings: SettingsModel) {
        self.browser = browser
        self.settings = settings
    }

    func refresh() {
        let server = settings.settings.localServer

        beginCheck()
        checkedAddress = server.baseURL
        check = Task { [weak self] in
            await self?.checkServer(at: server)
        }
    }

    func detect() {
        beginCheck()
        check = Task { [weak self] in
            await self?.detectServer()
        }
    }

    func addressDidChange() {
        guard settings.settings.localServer.baseURL != checkedAddress else { return }

        check?.cancel()
        check = nil
        checkedAddress = nil
        serverModels = []
        serverState = .unknown
    }

    private func beginCheck() {
        check?.cancel()
        serverState = .checking
    }

    private func checkServer(at server: LocalServer) async {
        guard !Task.isCancelled else { return }

        do throws(RewriteError) {
            let models = try await browser.models(at: server)

            guard !Task.isCancelled, isCurrent(server) else { return }

            showRunning(with: models)
        } catch {
            guard !Task.isCancelled, isCurrent(server) else { return }

            showNotRunning()
        }
    }

    private func detectServer() async {
        for known in LocalServer.knownServers {
            guard !Task.isCancelled else { return }

            let models: [String]

            do throws(RewriteError) {
                models = try await browser.models(at: LocalServer(baseURL: known.baseURL))
            } catch {
                guard !Task.isCancelled else { return }

                continue
            }

            guard !Task.isCancelled else { return }

            choose(known.baseURL, serving: models)

            return
        }

        guard !Task.isCancelled else { return }

        await reportNoKnownServer()
    }

    private func choose(_ baseURL: String, serving models: [String]) {
        let configured = settings.settings.localServer
        var server = LocalServer(baseURL: baseURL)

        if configured.baseURL == baseURL, models.contains(configured.model) {
            server.model = configured.model
        } else if let model = models.first {
            server.model = model
        }

        checkedAddress = baseURL
        settings.settings.localServer = server
        showRunning(with: models)
    }

    private func reportNoKnownServer() async {
        let configured = settings.settings.localServer

        guard LocalServer.knownServers.contains(where: { $0.baseURL == configured.baseURL }) else {
            checkedAddress = configured.baseURL
            await checkServer(at: configured)

            return
        }

        showNotRunning()
    }

    private func isCurrent(_ server: LocalServer) -> Bool {
        settings.settings.localServer.baseURL == server.baseURL
    }

    private func showRunning(with models: [String]) {
        serverModels = models
        serverState = .running
    }

    private func showNotRunning() {
        serverModels = []
        serverState = .notRunning
    }
}
