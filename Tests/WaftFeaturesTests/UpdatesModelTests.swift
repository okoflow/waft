import Testing
import WaftCore
@testable import WaftFeatures

struct UpdatesModelTests {
    @Test
    func `follows the updater's pending update and update session`() {
        var sessionChangeCount = 0
        let updater = FakeAppUpdater()
        let updates = UpdatesModel(updater: updater)
        updates.onShowingUpdateChange = { sessionChangeCount += 1 }
        updates.start()
        updater.report(isPending: true, isShowing: true)

        #expect(updates.hasPendingUpdate)
        #expect(updates.isShowingUpdate)
        #expect(sessionChangeCount == 1)

        updater.report(isPending: false, isShowing: false)

        #expect(!updates.hasPendingUpdate)
        #expect(!updates.isShowingUpdate)
        #expect(sessionChangeCount == 2)
    }
}
