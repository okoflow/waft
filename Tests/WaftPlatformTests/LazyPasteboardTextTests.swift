import AppKit
import Testing
@testable import WaftPlatform

struct LazyPasteboardTextTests {
    @Test
    func `provides its text for the requested type`() {
        let item = NSPasteboardItem()

        LazyPasteboardText("Hello.").pasteboard(nil, item: item, provideDataForType: .string)

        #expect(item.string(forType: .string) == "Hello.")
    }

    @Test
    func `counts a read only after it is armed`() {
        let text = LazyPasteboardText("Hello.")
        text.pasteboard(nil, item: NSPasteboardItem(), provideDataForType: .string)

        #expect(!text.wasReadAfterArming)

        text.arm()

        #expect(!text.wasReadAfterArming)

        text.pasteboard(nil, item: NSPasteboardItem(), provideDataForType: .string)

        #expect(text.wasReadAfterArming)
    }
}
