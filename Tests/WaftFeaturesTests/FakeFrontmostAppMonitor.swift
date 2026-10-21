import WaftCore

final class FakeFrontmostAppMonitor: FrontmostAppMonitor {
    let frontmostApp: RunningApp?
    let activations = AsyncStream<RunningApp> { $0.finish() }

    init(_ frontmostApp: RunningApp? = nil) {
        self.frontmostApp = frontmostApp
    }

    func start() {}
}
