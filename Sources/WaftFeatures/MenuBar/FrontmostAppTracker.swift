import Observation
import WaftCore

@Observable
final class FrontmostAppTracker {
    private(set) var app: RunningApp?

    private let monitor: any FrontmostAppMonitor

    init(monitor: any FrontmostAppMonitor) {
        self.monitor = monitor
    }

    func start() {
        app = monitor.frontmostApp
        monitor.start()

        Task { [weak self, activations = monitor.activations] in
            for await app in activations {
                self?.app = app
            }
        }
    }
}
