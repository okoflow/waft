@MainActor
package protocol AppUpdater: AnyObject {
    var isAvailable: Bool { get }
    var checksAutomatically: Bool { get set }

    func start(onPendingUpdateChange: @escaping @MainActor (Bool) -> Void, onSessionChange: @escaping @MainActor (Bool) -> Void)
    func checkForUpdates()
}
