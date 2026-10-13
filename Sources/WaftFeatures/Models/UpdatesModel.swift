import Observation
import WaftCore

@Observable
final class UpdatesModel {
    private(set) var hasPendingUpdate = false

    var checksAutomatically: Bool {
        didSet { updater.checksAutomatically = checksAutomatically }
    }

    private(set) var isShowingUpdate = false {
        didSet { onShowingUpdateChange?() }
    }

    @ObservationIgnored var onShowingUpdateChange: (() -> Void)?

    private let updater: any AppUpdater

    var isAvailable: Bool {
        updater.isAvailable
    }

    init(updater: any AppUpdater) {
        self.updater = updater
        checksAutomatically = updater.checksAutomatically
    }

    func check() {
        updater.checkForUpdates()
    }

    func start() {
        updater.start { [weak self] isPending in
            self?.hasPendingUpdate = isPending
        } onSessionChange: { [weak self] isShowing in
            self?.isShowingUpdate = isShowing
        }
    }
}
