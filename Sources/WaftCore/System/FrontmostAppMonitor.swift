@MainActor
package protocol FrontmostAppMonitor: AnyObject {
    var frontmostApp: RunningApp? { get }
    var activations: AsyncStream<RunningApp> { get }

    func start()
}
