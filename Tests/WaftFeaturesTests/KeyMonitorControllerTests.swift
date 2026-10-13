import Testing
import WaftCore
@testable import WaftFeatures

struct KeyMonitorControllerTests {
    @Test
    func `reports unavailable and retries until the monitor starts`() async {
        let monitor = FakeKeyEventMonitor(startsSuccessfully: false)
        let keyMonitor = KeyMonitorController(monitor: monitor, retryInterval: 0)
        keyMonitor.start()

        #expect(keyMonitor.status == .unavailable)

        monitor.startsSuccessfully = true

        #expect(await Poll.until(timeout: .seconds(5)) { keyMonitor.status == .ready })
    }

    @Test(arguments: [(false, 2), (true, 1)])
    func `starts again on a permission change only while unavailable`(startsSuccessfully: Bool, startCount: Int) {
        let monitor = FakeKeyEventMonitor(startsSuccessfully: startsSuccessfully)
        let keyMonitor = KeyMonitorController(monitor: monitor)
        keyMonitor.start()
        keyMonitor.permissionsDidChange()

        #expect(monitor.startCount == startCount)
    }

    @Test
    func `restarts a monitor that stopped while ready`() async {
        let monitor = FakeKeyEventMonitor()
        let keyMonitor = KeyMonitorController(monitor: monitor, healthCheckInterval: 0)
        keyMonitor.start()
        monitor.isRunning = false

        #expect(await Poll.until(timeout: .seconds(5)) { monitor.isRunning })
        #expect(monitor.startCount == 2)
        #expect(keyMonitor.status == .ready)
    }
}
