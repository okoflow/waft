import Foundation
import Observation
import os
import WaftCore

@Observable
final class SpeechModelController {
    private(set) var state = SpeechModelState()

    @ObservationIgnored var onReady: (() -> Void)?

    private let transcriber: any Transcriber
    private let settings: SettingsModel

    var modelDirectory: URL {
        transcriber.modelDirectory
    }

    init(transcriber: any Transcriber, settings: SettingsModel) {
        self.transcriber = transcriber
        self.settings = settings
    }

    func retry() {
        apply(.retryRequested)
    }

    func start() {
        Task {
            let isInstalled = await transcriber.isModelInstalled()

            apply(.started(isInstalled: isInstalled))
        }
    }

    func reload() {
        apply(.reloadRequested)
    }

    private func apply(_ event: SpeechModelState.Event) {
        let effects = state.handle(event)
        guard !effects.isEmpty else { return }

        Task {
            for effect in effects {
                await perform(effect)
            }
        }
    }

    private func perform(_ effect: SpeechModelState.Effect) async {
        switch effect {
        case .deleteModel: await deleteModel()
        case .download: await download()
        case .load: await load()
        }
    }

    private func deleteModel() async {
        do {
            try await transcriber.deleteModel()
        } catch {
            let cause = error as NSError
            Logger.speechModel
                .error("Couldn't delete the speech model: \(cause.domain, privacy: .public) \(cause.code, privacy: .public)")
        }
    }

    private func download() async {
        do {
            try await transcriber.downloadModel { [weak self] fraction in
                Task { @MainActor in self?.apply(.downloadProgressed(fraction)) }
            }

            apply(.downloaded)
        } catch {
            let cause = error as NSError
            Logger.speechModel.error("Download failed: \(cause.domain, privacy: .public) \(cause.code, privacy: .public)")

            apply(.failed(error.localizedDescription))
        }
    }

    private func load() async {
        do {
            let duration = try await transcriber.loadModel(for: settings.settings.languages.languages)

            Logger.speechModel
                .info("Loaded the speech model in \(duration.formatted(.units(allowed: [.seconds])), privacy: .public)")

            apply(.loaded)

            if state.isReady {
                onReady?()
            }
        } catch {
            let cause = error as NSError
            Logger.speechModel.error("Load failed: \(cause.domain, privacy: .public) \(cause.code, privacy: .public)")

            apply(.failed(error.localizedDescription))
        }
    }
}
