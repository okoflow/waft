import CoreGraphics
import Testing
@testable import WaftFeatures

struct HUDLayoutTests {
    @Test
    func `rests inside the notch and spans it with a wing on each side`() {
        let layout = HUDLayout()
        layout.place(around: CGSize(width: 185, height: 38))

        #expect(layout.gap == 185)
        #expect(layout.topHeight == 38)
        #expect(layout.contentSize == CGSize(width: 185, height: 38))
        #expect(layout.spanWidth == 185 + 2 * HUDLayout.wing)
    }

    @Test
    func `rests hidden above a screen without a notch and keeps the row height`() {
        let layout = HUDLayout()
        layout.place(around: nil)

        #expect(layout.gap == 0)
        #expect(layout.topHeight == 32)
        #expect(layout.contentSize == CGSize(width: 2 * HUDLayout.wing, height: 0))
    }
}
