package struct RecordingID: Comparable, Hashable, Sendable {
    package static let none = RecordingID(rawValue: 0)

    private let rawValue: Int

    package var next: RecordingID {
        RecordingID(rawValue: rawValue + 1)
    }

    package static func < (left: RecordingID, right: RecordingID) -> Bool {
        left.rawValue < right.rawValue
    }
}
