import AppKit
import Testing
import WaftCore
@testable import WaftPlatform

@MainActor
struct PasteboardSnapshotTests {
    private static let privateType = NSPasteboard.PasteboardType("com.example.private")
    private static let otherPrivateType = NSPasteboard.PasteboardType("com.example.other-private")
    private static let promiseType = NSPasteboard.PasteboardType("com.apple.pasteboard.promised-file-url")

    private static func item(_ contents: [NSPasteboard.PasteboardType: Data]) -> NSPasteboardItem {
        let item = NSPasteboardItem()

        for (type, data) in contents {
            item.setData(data, forType: type)
        }

        return item
    }

    @Test
    func `restores every type of every item`() throws {
        try NSPasteboard.withTemporary { pasteboard in
            pasteboard.clearContents()
            pasteboard.writeObjects([
                Self.item([.string: Data("Hello.".utf8), Self.privateType: Data([1])]),
                Self.item([Self.privateType: Data([2])]),
                Self.item([.html: Data("<p>Hi.</p>".utf8)]),
            ])

            let snapshot = PasteboardSnapshot.take(from: pasteboard, rareTypesTimeBudget: .seconds(60))

            pasteboard.writePrivately("Dictated.")
            snapshot.restore(to: pasteboard)

            let items = try #require(pasteboard.pasteboardItems)

            #expect(snapshot.plan == .restore)
            #expect(items.map { Set($0.types) } == [[.string, Self.privateType], [Self.privateType], [.html]])
            #expect(items.map { $0.string(forType: .string) } == ["Hello.", nil, nil])
            #expect(items.map { $0.data(forType: Self.privateType) } == [Data([1]), Data([2]), nil])
            #expect(items.map { $0.string(forType: .html) } == [nil, nil, "<p>Hi.</p>"])
        }
    }

    @Test
    func `restores the types of an item in the order the app declared them`() throws {
        try NSPasteboard.withTemporary { pasteboard in
            let copied = NSPasteboardItem()
            copied.setData(Data([1]), forType: Self.privateType)
            copied.setString("<p>Hi.</p>", forType: .html)
            copied.setString("Hi.", forType: .string)

            pasteboard.clearContents()
            pasteboard.writeObjects([copied])

            let snapshot = PasteboardSnapshot.take(from: pasteboard)

            pasteboard.writePrivately("Dictated.")
            snapshot.restore(to: pasteboard)

            let items = try #require(pasteboard.pasteboardItems)

            #expect(items.map(\.types) == [[Self.privateType, .html, .string]])
        }
    }

    @Test
    func `leaves out a type it cannot read and a promise nobody could keep`() throws {
        try NSPasteboard.withTemporary { pasteboard in
            let provider = FakePasteboardItemDataProvider()
            let copied = Self.item([.string: Data("Hello.".utf8), Self.promiseType: Data([1])])
            copied.setDataProvider(provider, forTypes: [Self.privateType])

            pasteboard.clearContents()
            pasteboard.writeObjects([copied])

            let snapshot = PasteboardSnapshot.take(from: pasteboard)

            pasteboard.writePrivately("Dictated.")
            snapshot.restore(to: pasteboard)

            let items = try #require(pasteboard.pasteboardItems)

            #expect(snapshot.plan == .restore)
            #expect(items.map(\.types) == [[.string]])
            #expect(pasteboard.string(forType: .string) == "Hello.")
        }
    }

    @Test(arguments: [false, true])
    func `keeps the dictated text rather than a clipboard that lost an item`(hasReadableItem: Bool) {
        NSPasteboard.withTemporary { pasteboard in
            let provider = FakePasteboardItemDataProvider()
            let unreadable = NSPasteboardItem()
            unreadable.setDataProvider(provider, forTypes: [Self.privateType])

            let readable = hasReadableItem ? [Self.item([.string: Data("Hello.".utf8)])] : []

            pasteboard.clearContents()
            pasteboard.writeObjects(readable + [unreadable])

            let snapshot = PasteboardSnapshot.take(from: pasteboard)

            pasteboard.writePrivately("Dictated.")
            snapshot.restore(to: pasteboard)

            #expect(snapshot.plan == .skip(reason: .uncapturedItem))
            #expect(pasteboard.string(forType: .string) == "Dictated.")
        }
    }

    @Test
    func `restores an empty clipboard as empty`() throws {
        try NSPasteboard.withTemporary { pasteboard in
            pasteboard.clearContents()

            let snapshot = PasteboardSnapshot.take(from: pasteboard)

            pasteboard.writePrivately("Dictated.")
            snapshot.restore(to: pasteboard)

            let items = try #require(pasteboard.pasteboardItems)

            #expect(snapshot.plan == .restore)
            #expect(items.isEmpty)
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

    @Test
    func `drops the other types that do not fit the size limit and restores the ones every app reads`() throws {
        try NSPasteboard.withTemporary { pasteboard in
            let overLimit = Data(count: PasteboardRestorePolicy.maximumSnapshotBytes + 1)

            pasteboard.clearContents()
            pasteboard.writeObjects([Self.item([.string: Data("Hello.".utf8), Self.privateType: overLimit])])

            let snapshot = PasteboardSnapshot.take(from: pasteboard)

            pasteboard.writePrivately("Dictated.")
            snapshot.restore(to: pasteboard)

            let items = try #require(pasteboard.pasteboardItems)

            #expect(snapshot.plan == .restore)
            #expect(items.map(\.types) == [[.string]])
            #expect(pasteboard.string(forType: .string) == "Hello.")
        }
    }

    @Test
    func `keeps the dictated text rather than an item whose only type does not fit the size limit`() {
        NSPasteboard.withTemporary { pasteboard in
            let overLimit = Data(count: PasteboardRestorePolicy.maximumSnapshotBytes + 1)

            pasteboard.clearContents()
            pasteboard.writeObjects([Self.item([Self.privateType: overLimit])])

            let snapshot = PasteboardSnapshot.take(from: pasteboard)

            pasteboard.writePrivately("Dictated.")
            snapshot.restore(to: pasteboard)

            #expect(snapshot.plan == .skip(reason: .uncapturedItem))
            #expect(pasteboard.string(forType: .string) == "Dictated.")
        }
    }

    @Test
    func `leaves out the other types once reading them has taken longer than the time budget`() throws {
        try NSPasteboard.withTemporary { pasteboard in
            let copied = NSPasteboardItem()
            copied.setData(Data([1]), forType: Self.privateType)
            copied.setData(Data([2]), forType: Self.otherPrivateType)
            copied.setString("Hello.", forType: .string)

            pasteboard.clearContents()
            pasteboard.writeObjects([copied])

            let snapshot = PasteboardSnapshot.take(from: pasteboard, rareTypesTimeBudget: .zero)

            pasteboard.writePrivately("Dictated.")
            snapshot.restore(to: pasteboard)

            let items = try #require(pasteboard.pasteboardItems)

            #expect(snapshot.plan == .restore)
            #expect(items.map(\.types) == [[Self.privateType, .string]])
            #expect(pasteboard.string(forType: .string) == "Hello.")
        }
    }

    @Test
    func `saves one type of an item that has no other, even after the time budget`() throws {
        try NSPasteboard.withTemporary { pasteboard in
            let first = NSPasteboardItem()
            first.setData(Data([1]), forType: Self.privateType)

            let second = NSPasteboardItem()
            second.setData(Data([2]), forType: Self.privateType)
            second.setData(Data([3]), forType: Self.otherPrivateType)

            pasteboard.clearContents()
            pasteboard.writeObjects([first, second])

            let snapshot = PasteboardSnapshot.take(from: pasteboard, rareTypesTimeBudget: .zero)

            pasteboard.writePrivately("Dictated.")
            snapshot.restore(to: pasteboard)

            let items = try #require(pasteboard.pasteboardItems)

            #expect(snapshot.plan == .restore)
            #expect(items.map(\.types) == [[Self.privateType], [Self.privateType]])
            #expect(items.map { $0.data(forType: Self.privateType) } == [Data([1]), Data([2])])
        }
    }
}

private final class FakePasteboardItemDataProvider: NSObject, NSPasteboardItemDataProvider {
    func pasteboard(_: NSPasteboard?, item _: NSPasteboardItem, provideDataForType _: NSPasteboard.PasteboardType) {}
}
