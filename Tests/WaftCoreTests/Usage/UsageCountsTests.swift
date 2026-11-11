import Foundation
import Testing
import WaftCore

struct UsageCountsTests {
    @Test(arguments: [
        (UsageEvent.dictation(.raw), "rawDictations"),
        (.dictation(.light), "lightDictations"),
        (.dictation(.clean), "cleanDictations"),
        (.dictation(.formal), "formalDictations"),
        (.dictation(.translate), "translateDictations"),
        (.dictation(.custom(UUID())), "customDictations"),
        (.voiceEdit, "voiceEdits"),
        (.selectionAction, "selectionActions"),
        (.translation, "translations"),
        (.fileTranscription, "fileTranscriptions"),
    ])
    func `counts an event under its own number and no other`(event: UsageEvent, number: String) throws {
        var counts = UsageCounts()
        counts.count(event)

        let encoded = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(counts)) as? [String: Int])

        #expect(encoded.filter { $0.value > 0 } == [number: 1])
    }
}
