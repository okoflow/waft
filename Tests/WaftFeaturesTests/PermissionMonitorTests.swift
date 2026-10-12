import Testing
import WaftCore
@testable import WaftFeatures

struct PermissionMonitorTests {
    @Test(arguments: [(PermissionStatus.granted, 1), (.notDetermined, 0)])
    func `reports a change after a request`(answer: PermissionStatus, changes: Int) async {
        var changeCount = 0
        let monitor = PermissionMonitor(provider: FakePermissionProvider([:], answers: [.microphone: answer]))
        monitor.onChange = { changeCount += 1 }
        await monitor.request(.microphone)

        #expect(monitor.status(of: .microphone) == answer)
        #expect(changeCount == changes)
    }

    @Test(arguments: [(PermissionStatus.granted, true), (.denied, false)])
    func `needs every permission`(accessibility: PermissionStatus, allGranted: Bool) {
        let monitor = PermissionMonitor(provider: FakePermissionProvider([.microphone: .granted, .accessibility: accessibility]))

        #expect(monitor.allGranted == allGranted)
    }
}
