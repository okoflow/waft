import Testing
@testable import WaftFeatures

struct HUDMessageTests {
    @Test(arguments: [
        (HUDMessage.Kind.information, "", String?.none, Duration.seconds(2)),
        (.information, String(repeating: "a", count: 20), String(repeating: "b", count: 10), .seconds(4)),
        (.warning, String(repeating: "a", count: 300), nil, .seconds(10)),
        (.pasted, String(repeating: "a", count: 300), nil, .seconds(4)),
    ])
    func `shows a message for its reading time within its kind's cap`(
        kind: HUDMessage.Kind,
        title: String,
        detail: String?,
        duration: Duration,
    ) {
        #expect(HUDMessage(kind: kind, title: title, detail: detail).duration == duration)
    }
}
