import Testing
@testable import WaftFeatures

struct HUDMessageTests {
    @Test(arguments: [
        (HUDMessage.Kind.information, "", String?.none, Duration.seconds(2)),
        (.information, String(repeating: "a", count: 20), String(repeating: "b", count: 10), .seconds(4)),
        (.warning, String(repeating: "a", count: 300), nil, .seconds(10)),
        (.pasted, String(repeating: "a", count: 300), nil, .seconds(5)),
        (.pasted, String(repeating: "a", count: 300), String(repeating: "b", count: 150), .seconds(10)),
    ])
    func `shows a message for its reading time, and a pasted one for at least five seconds`(
        kind: HUDMessage.Kind,
        title: String,
        detail: String?,
        duration: Duration,
    ) {
        #expect(HUDMessage(kind: kind, title: title, detail: detail).duration == duration)
    }
}
