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

    @ObservationIgnored private var check: Task<Void, Never>?

    private let browser: any LocalServerBrowsing
    private let settings: SettingsModel

    init(browser: any LocalServerBrowsing, settings: SettingsModel) {
        self.browser = browser
        self.settings = settings
    }

    func refresh() {
        let server = settings.settings.localServer

        beginCheck()
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

    private func beginCheck() {
        check?.cancel()
        serverState = .checking
    }

    private func checkServer(at server: LocalServer) async {
        do throws(RewriteError) {
            let models = try await browser.models(at: server)

            guard !Task.isCancelled else { return }

            showRunning(with: models)
        } catch {
            guard !Task.isCancelled else { return }

            showNotRunning()
        }
    }

    private func detectServer() async {
        for known in LocalServer.knownServers {
            var server = LocalServer(baseURL: known.baseURL)
            let models: [String]

            do throws(RewriteError) {
                models = try await browser.models(at: server)
            } catch {
                continue
            }

            guard !Task.isCancelled else { return }

            if let model = models.first {
                server.model = model
            }

            settings.settings.localServer = server
            showRunning(with: models)

            return
        }

        guard !Task.isCancelled else { return }

        showNotRunning()
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
