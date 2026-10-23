import CoreGraphics
import Testing
@testable import WaftFeatures

struct ForeignWindowTests {
    private static let screen = CGRect(x: 0, y: 0, width: 1728, height: 1117)
    private static let notch = CGRect(x: 771, y: 0, width: 185, height: 32)

    @Test
    func `finds the highest window another app keeps over the notch`() {
        let windows = [
            ForeignWindow(level: 27, bounds: CGRect(x: 544, y: 0, width: 640, height: 200)),
            ForeignWindow(level: 101, bounds: CGRect(x: 700, y: 0, width: 330, height: 40)),
        ]

        #expect(ForeignWindow.coveringLevel(of: Self.notch, on: Self.screen, among: windows) == 101)
    }

    @Test(arguments: [
        ForeignWindow(level: 24, bounds: CGRect(x: 0, y: 0, width: 1728, height: 33)),
        ForeignWindow(level: 21, bounds: CGRect(x: 0, y: 0, width: 1728, height: 1117)),
        ForeignWindow(level: 0, bounds: CGRect(x: 600, y: 0, width: 500, height: 400)),
        ForeignWindow(level: 25, bounds: CGRect(x: 1200, y: 0, width: 30, height: 33)),
        ForeignWindow(level: 101, bounds: CGRect(x: 780, y: 32, width: 240, height: 300)),
    ])
    func `ignores the menu bar, full screen overlays, app windows, status items, and menus`(window: ForeignWindow) {
        #expect(ForeignWindow.coveringLevel(of: Self.notch, on: Self.screen, among: [window]) == nil)
    }
}
