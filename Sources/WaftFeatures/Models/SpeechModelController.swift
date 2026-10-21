import Foundation
import Observation
import os
import WaftCore

@Observable
final class SpeechModelController {
    private(set) var state = SpeechModelState()

    @ObservationIgnored var onReady: (() -> Void)?

    @ObservationIgnored private var effectsTask: Task<Void, Never>?
    @ObservationIgnored private var downloadTask: Task<Void, Never>?

    private let transcriber: any Transcriber
    private let settings: SettingsModel
    private let pro: ProModel
    private let urlOpener: any URLOpener

    var modelDirectory: URL {
        transcriber.modelDirectory(for: chosenModel)
    }

    var chosenModel: SpeechModel {
        settings.settings.speechModel.usable(withProUnlocked: pro.isUnlocked)
    }

    init(transcriber: any Transcriber, settings: SettingsModel, pro: ProModel, urlOpener: any URLOpener) {
        self.transcriber = transcriber
        self.settings = settings
        self.pro = pro
        self.urlOpener = urlOpener
    }

    func retry() {
        apply(.retryRequested)
    }

    func revealInFinder() {
        urlOpener.reveal(modelDirectory)
    }

    func start() {
        Task {
            while true {
                let model = chosenModel

                let isInstalled = await transcriber.isModelInstalled(model)

                guard chosenModel == model else { continue }

                apply(.started(model, isInstalled: isInstalled))

                return
            }
        }
    }

    func reload() {
        apply(.reloadRequested)
    }

    func modelDidChange() {
        Task {
            let model = chosenModel

            let isInstalled = await transcriber.isModelInstalled(model)

            guard chosenModel == model else { return }

            apply(.chosen(model, isInstalled: isInstalled))
        }
    }

    private func apply(_ event: SpeechModelState.Event) {
        let effects = state.handle(event)
        guard !effects.isEmpty else { return }

        let previous = effectsTask

        effectsTask = Task {
            await previous?.value

            for effect in effects {
                await perform(effect)
            }
        }
    }

    private func perform(_ effect: SpeechModelState.Effect) async {
        switch effect {
        case .cancelDownload: await cancelDownload()
        case let .deleteModel(model): await deleteModel(model)
        case let .download(model): download(model)
        case let .load(model): await load(model)
        }
    }

    private func cancelDownload() async {
        guard let downloadTask else { return }

        downloadTask.cancel()
        await downloadTask.value
    }

    private func deleteModel(_ model: SpeechModel) async {
        do {
            try await transcriber.deleteModel(model)
        } catch {
            Logger.speechModel.error("Couldn't delete the speech model: \(error.logDescription, privacy: .public)")
        }
    }

    private func download(_ model: SpeechModel) {
        downloadTask = Task { await fetch(model) }
    }

    private func fetch(_ model: SpeechModel) async {
        do {
            try await transcriber.downloadModel(model) { [weak self] fraction in
                Task { @MainActor in self?.apply(.downloadProgressed(model, fraction)) }
            }

            apply(.downloaded(model))
        } catch {
            guard !Task.isCancelled else { return }

            Logger.speechModel.error("Download failed: \(error.logDescription, privacy: .public)")

            apply(.failed(model, error.localizedDescription))
        }
    }

    private func load(_ model: SpeechModel) async {
        do {
            let duration = try await transcriber.loadModel(model, for: settings.settings.languages.languages)

            Logger.speechModel
                .info("Loaded the speech model in \(duration.formatted(.units(allowed: [.seconds])), privacy: .public)")

            apply(.loaded(model))

            if state.isReady {
                onReady?()
            }
        } catch {
            Logger.speechModel.error("Load failed: \(error.logDescription, privacy: .public)")

            apply(.failed(model, error.localizedDescription))
        }
    }
}
