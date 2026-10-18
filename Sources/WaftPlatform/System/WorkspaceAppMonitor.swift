package import WaftCore
import AppKit

@MainActor
package final class WorkspaceAppMonitor: FrontmostAppMonitor {
    package let activations: AsyncStream<RunningApp>

    private let continuation: AsyncStream<RunningApp>.Continuation
    private var observer: (any NSObjectProtocol)?

    package var frontmostApp: RunningApp? {
        Self.app(from: NSWorkspace.shared.frontmostApplication)
    }

    package init() {
        let stream = AsyncStream.makeStream(of: RunningApp.self)
        activations = stream.stream
        continuation = stream.continuation
    }

    private nonisolated static func app(from running: NSRunningApplication?) -> RunningApp? {
        guard let running else { return nil }

        return RunningApp.trackable(bundleIdentifier: running.bundleIdentifier, name: running.localizedName)
    }

    package func start() {
        guard observer == nil else { return }

        let continuation = continuation

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main,
        ) { notification in
            let running = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication

            if let app = Self.app(from: running) {
                continuation.yield(app)
            }
        }
    }
}
