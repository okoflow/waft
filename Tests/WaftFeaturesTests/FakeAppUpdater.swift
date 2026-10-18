import WaftCore

final class FakeAppUpdater: AppUpdater {
    let isAvailable = true
    var checksAutomatically = true

    private var onPendingUpdateChange: (@MainActor (Bool) -> Void)?
    private var onSessionChange: (@MainActor (Bool) -> Void)?

    func start(onPendingUpdateChange: @escaping @MainActor (Bool) -> Void, onSessionChange: @escaping @MainActor (Bool) -> Void) {
        self.onPendingUpdateChange = onPendingUpdateChange
        self.onSessionChange = onSessionChange
    }

    func checkForUpdates() {}

    func report(isPending: Bool, isShowing: Bool) {
        onPendingUpdateChange?(isPending)
        onSessionChange?(isShowing)
    }
}
