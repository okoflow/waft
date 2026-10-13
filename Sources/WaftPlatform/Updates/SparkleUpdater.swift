import AppKit
import Sparkle
import WaftCore

@MainActor
package final class SparkleUpdater: AppUpdater {
    package let isAvailable: Bool

    private let reminders: UpdateReminders
    private let controller: SPUStandardUpdaterController

    package var checksAutomatically: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set { controller.updater.automaticallyChecksForUpdates = newValue }
    }

    package init() {
        let reminders = UpdateReminders()

        isAvailable = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") != nil
        self.reminders = reminders
        controller = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: reminders)
    }

    package func start(
        onPendingUpdateChange: @escaping @MainActor (Bool) -> Void,
        onSessionChange: @escaping @MainActor (Bool) -> Void,
    ) {
        guard isAvailable else { return }

        reminders.onPendingUpdateChange = onPendingUpdateChange
        reminders.onSessionChange = onSessionChange
        controller.startUpdater()
    }

    package func checkForUpdates() {
        guard isAvailable else { return }

        NSApp.activate()
        controller.checkForUpdates(nil)
    }
}

@MainActor
private final class UpdateReminders: NSObject, SPUStandardUserDriverDelegate {
    var onPendingUpdateChange: (@MainActor (Bool) -> Void)?
    var onSessionChange: (@MainActor (Bool) -> Void)?

    var supportsGentleScheduledUpdateReminders: Bool {
        true
    }

    func standardUserDriverWillHandleShowingUpdate(
        _: Bool,
        forUpdate _: SUAppcastItem,
        state: SPUUserUpdateState,
    ) {
        onSessionChange?(true)

        guard !state.userInitiated else { return }

        onPendingUpdateChange?(true)
    }

    func standardUserDriverDidReceiveUserAttention(forUpdate _: SUAppcastItem) {
        onPendingUpdateChange?(false)
    }

    func standardUserDriverWillFinishUpdateSession() {
        onPendingUpdateChange?(false)
        onSessionChange?(false)
    }
}
