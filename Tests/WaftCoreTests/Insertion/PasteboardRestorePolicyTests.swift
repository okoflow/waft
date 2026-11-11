import Testing
@testable import WaftCore

struct PasteboardRestorePolicyTests {
    typealias Policy = PasteboardRestorePolicy

    private static let privateItem = Policy.Plan.skip(reason: .privateItem)
    private static let tooLarge = Policy.Plan.skip(reason: .tooLarge)
    private static let uncapturedItem = Policy.Plan.skip(reason: .uncapturedItem)

    @Test(arguments: [
        (["public.png", "public.tiff", "public.utf8-plain-text"], ["public.png", "public.utf8-plain-text"]),
        (["public.tiff", "public.rtf"], ["public.tiff", "public.rtf"]),
        (
            ["com.example.private", "public.html", "dyn.ah62d4rv4gu8y"],
            ["com.example.private", "public.html", "dyn.ah62d4rv4gu8y"],
        ),
        ([Policy.concealedType, "public.utf8-plain-text"], [Policy.concealedType, "public.utf8-plain-text"]),
        (["com.apple.pasteboard.promised-file-url", "com.apple.NSFilePromiseItemMetaData", "public.png"], ["public.png"]),
        (["NSPromiseContentsPboardType", "Apple files promise pasteboard type"], []),
        ([], []),
    ])
    func `saves every type but a promise and a TIFF next to its PNG`(types: [String], expected: [String]) {
        #expect(Policy.typesToSave(from: types) == expected)
    }

    @Test(arguments: [
        ("public.utf8-plain-text", true),
        ("public.png", true),
        ("public.file-url", true),
        (Policy.waftType, true),
        ("com.example.private", false),
        ("dyn.ah62d4rv4gu8y", false),
    ])
    func `tells the types every app reads from the rest`(type: String, isStandard: Bool) {
        #expect(Policy.isStandard(type) == isStandard)
    }

    @Test(arguments: [
        ([Policy.concealedType], privateItem),
        ([Policy.transientType, "public.utf8-plain-text"], privateItem),
        ([Policy.transientType, Policy.waftType], Policy.Plan.restore),
        (["public.utf8-plain-text"], .restore),
    ])
    func `skips private clipboard items unless they are Waft's own`(types: [String], expected: Policy.Plan) {
        #expect(Policy.plan(currentTypes: types, snapshotBytes: 100, hasUncapturedItem: false) == expected)
    }

    @Test(arguments: [
        (Policy.maximumSnapshotBytes, Policy.Plan.restore),
        (Policy.maximumSnapshotBytes + 1, tooLarge),
    ])
    func `skips clipboards larger than five megabytes`(bytes: Int, expected: Policy.Plan) {
        #expect(Policy.plan(currentTypes: ["public.png"], snapshotBytes: bytes, hasUncapturedItem: false) == expected)
    }

    @Test(arguments: [(false, Policy.Plan.restore), (true, uncapturedItem)])
    func `skips a clipboard with an item that could not be captured`(hasUncapturedItem: Bool, expected: Policy.Plan) {
        #expect(Policy.plan(currentTypes: ["public.png"], snapshotBytes: 100, hasUncapturedItem: hasUncapturedItem) == expected)
    }

    @Test(arguments: [
        ([Policy.concealedType], Int.max, privateItem),
        (["public.png"], .max, tooLarge),
    ])
    func `reports a private item before its size and its size before an item that could not be captured`(
        types: [String],
        bytes: Int,
        expected: Policy.Plan,
    ) {
        #expect(Policy.plan(currentTypes: types, snapshotBytes: bytes, hasUncapturedItem: true) == expected)
    }
}
