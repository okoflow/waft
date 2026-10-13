import Foundation
import Observation
import os
import WaftCore

@Observable
final class SpeechModelController {
    private(set) var state = SpeechModelState()

    @ObservationIgnored var onReady: (() -> Void)?

    @ObservationIgnored private var downloadTask: Task<Void, Never>?

    private let transcriber: any Transcriber
    private let settings: SettingsModel
    private let pro: ProModel

    var modelDirectory: URL {
        transcriber.modelDirectory(for: chosenModel)
    }

    private var chosenModel: SpeechModel {
        settings.settings.speechModel.usable(withProUnlocked: pro.isUnlocked)
    }

    init(transcriber: any Transcriber, settings: SettingsModel, pro: ProModel) {
        self.transcriber = transcriber
        self.settings = settings
        self.pro = pro
    }

    func retry() {
        apply(.retryRequested)
    }

    func start() {
        Task {
            let model = chosenModel
            let isInstalled = await transcriber.isModelInstalled(model)

            apply(.started(model, isInstalled: isInstalled))
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

        Task {
            for effect in effects {
                await perform(effect)
            }
        }
    }

    private func perform(_ effect: SpeechModelState.Effect) async {
        switch effect {
        case .cancelDownload: await cancelDownload()
        case let .deleteModel(model): await deleteModel(model)
        case let .download(model): await download(model)
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
            let cause = error as NSError
            Logger.speechModel
                .error("Couldn't delete the speech model: \(cause.domain, privacy: .public) \(cause.code, privacy: .public)")
        }
    }

    private func download(_ model: SpeechModel) async {
        let task = Task { await fetch(model) }
        downloadTask = task

        await task.value
    }

    private func fetch(_ model: SpeechModel) async {
        do {
            try await transcriber.downloadModel(model) { [weak self] fraction in
                Task { @MainActor in self?.apply(.downloadProgressed(model, fraction)) }
            }

            apply(.downloaded(model))
        } catch {
            guard !Task.isCancelled else { return }

            let cause = error as NSError
            Logger.speechModel.error("Download failed: \(cause.domain, privacy: .public) \(cause.code, privacy: .public)")

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
            let cause = error as NSError
            Logger.speechModel.error("Load failed: \(cause.domain, privacy: .public) \(cause.code, privacy: .public)")

            apply(.failed(model, error.localizedDescription))
        }
    }
}
