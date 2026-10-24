import AppKit
import Testing
import WaftCore
@testable import WaftPlatform

struct PasteboardSnapshotTests {
    private static let privateType = NSPasteboard.PasteboardType("com.example.private")

    private static func item(_ contents: [NSPasteboard.PasteboardType: Data]) -> NSPasteboardItem {
        let item = NSPasteboardItem()

        for (type, data) in contents {
            item.setData(data, forType: type)
        }

        return item
    }

    @Test
    func `restores the restorable types of every item and drops the rest`() throws {
        try NSPasteboard.withTemporary { pasteboard in
            pasteboard.clearContents()
            pasteboard.writeObjects([
                Self.item([.string: Data("Hello.".utf8), Self.privateType: Data([1])]),
                Self.item([Self.privateType: Data([2])]),
                Self.item([.html: Data("<p>Hi.</p>".utf8)]),
            ])

            let snapshot = PasteboardSnapshot.take(from: pasteboard)

            pasteboard.writePrivately("Dictated.")
            snapshot.restore(to: pasteboard)

            let items = try #require(pasteboard.pasteboardItems)

            #expect(items.map { Set($0.types) } == [[.string], [.html]])
            #expect(items.map { $0.string(forType: .string) } == ["Hello.", nil])
            #expect(items.map { $0.string(forType: .html) } == [nil, "<p>Hi.</p>"])
        }
    }

    @Test
    func `restores an earlier transcript with the markers that keep it private`() throws {
        try NSPasteboard.withTemporary { pasteboard in
            pasteboard.writePrivately("Earlier.")

            let snapshot = PasteboardSnapshot.take(from: pasteboard)

            pasteboard.writePrivately("Dictated.")
            snapshot.restore(to: pasteboard)

            let types = try #require(pasteboard.types).map(\.rawValue)

            #expect(snapshot.plan == .restore)
            #expect(pasteboard.string(forType: .string) == "Earlier.")
            #expect(Set(types).isSuperset(of: PasteboardRestorePolicy.markerTypes))
        }
    }

    @Test(arguments: [(1, true), (2, false)])
    func `restores a clipboard only while its items together fit the size limit`(itemCount: Int, isRestored: Bool) {
        NSPasteboard.withTemporary { pasteboard in
            let halfOfLimit = Data(count: PasteboardRestorePolicy.maximumSnapshotBytes / 2 + 1)

            pasteboard.clearContents()
            pasteboard.writeObjects((0 ..< itemCount).map { _ in Self.item([.string: halfOfLimit]) })

            let snapshot = PasteboardSnapshot.take(from: pasteboard)

            #expect((snapshot.plan == .restore) == isRestored)
        }
    }
}
