import AppKit
import Testing
import WaftCore
@testable import WaftPlatform

@MainActor
struct NSPasteboardPrivateTests {
    @Test
    func `writes text as a plain string marked as private`() throws {
        try NSPasteboard.withTemporary { pasteboard in
            pasteboard.writePrivately("Dictated.")

            let types = try #require(pasteboard.types).map(\.rawValue)

            #expect(pasteboard.string(forType: .string) == "Dictated.")
            #expect(Set(types).isSuperset(of: PasteboardRestorePolicy.markerTypes))
        }
    }

    @Test(arguments: ["org.nspasteboard.TransientType", "org.nspasteboard.ConcealedType"])
    func `marks the text with the types that tell clipboard managers to skip it`(type: String) throws {
        try NSPasteboard.withTemporary { pasteboard in
            pasteboard.writePrivately("Dictated.")

            let types = try #require(pasteboard.types).map(\.rawValue)

            #expect(types.contains(type))
        }
    }

    @Test
    func `returns the change count of its own write`() {
        NSPasteboard.withTemporary { pasteboard in
            let changeCount = pasteboard.writePrivately(NSPasteboardItem())

            #expect(changeCount == pasteboard.changeCount)
        }
    }
}
