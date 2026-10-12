import Testing
@testable import WaftCore

struct PasteboardRestorePolicyTests {
    typealias Policy = PasteboardRestorePolicy

    private static let privateItem = Policy.Plan.skip(reason: "the clipboard holds a concealed or transient item")
    private static let tooLarge = Policy.Plan.skip(reason: "the clipboard holds more than 5 MB")

    @Test(arguments: [
        (["public.png", "public.tiff", "public.utf8-plain-text"], ["public.png", "public.utf8-plain-text"]),
        (["public.tiff", "public.rtf"], ["public.tiff", "public.rtf"]),
        (["com.example.private", "public.html", "dyn.ah62d4rv4gu8y"], ["public.html"]),
        ([Policy.concealedType, "public.utf8-plain-text"], [Policy.concealedType, "public.utf8-plain-text"]),
        ([], []),
    ])
    func `saves only restorable types`(types: [String], expected: [String]) {
        #expect(Policy.typesToSave(from: types) == expected)
    }

    @Test(arguments: [
        ([Policy.concealedType], privateItem),
        ([Policy.transientType, "public.utf8-plain-text"], privateItem),
        ([Policy.transientType, Policy.waftType], Policy.Plan.restore),
        (["public.utf8-plain-text"], .restore),
    ])
    func `skips private clipboard items unless they are Waft's own`(types: [String], expected: Policy.Plan) {
        #expect(Policy.plan(currentTypes: types, snapshotBytes: 100) == expected)
    }

    @Test(arguments: [
        (Policy.maximumSnapshotBytes, Policy.Plan.restore),
        (Policy.maximumSnapshotBytes + 1, tooLarge),
        (0, .restore),
    ])
    func `skips clipboards larger than five megabytes`(bytes: Int, expected: Policy.Plan) {
        #expect(Policy.plan(currentTypes: ["public.png"], snapshotBytes: bytes) == expected)
    }

    @Test
    func `reports a private item before its size`() {
        #expect(Policy.plan(currentTypes: [Policy.concealedType], snapshotBytes: .max) == Self.privateItem)
    }
}
