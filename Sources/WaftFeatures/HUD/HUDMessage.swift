import Foundation

struct HUDMessage: Equatable {
    enum Kind {
        case pasted
        case copied
        case information
        case warning
    }

    private static let glanceTime = 5.0

    let kind: Kind
    let title: String
    let detail: String?

    var isCopyable: Bool {
        kind == .pasted
    }

    var duration: Duration {
        .milliseconds(Int(seconds * 1000))
    }

    private var seconds: Double {
        guard kind == .pasted else { return Self.readingTime(of: [title, detail]) }

        return max(Self.glanceTime, Self.readingTime(of: [detail]))
    }

    init(kind: Kind, title: String, detail: String? = nil) {
        self.kind = kind
        self.title = title
        self.detail = detail
    }

    static func keptOutOfPasswordField(_ text: String) -> HUDMessage {
        HUDMessage(kind: .copied, title: text, detail: String(localized: "Not pasted into a password field"))
    }

    static func recordingFailed(_ detail: String) -> HUDMessage {
        HUDMessage(kind: .warning, title: String(localized: "Recording failed"), detail: detail)
    }

    static func recordingCutShort(_ detail: String) -> HUDMessage {
        HUDMessage(kind: .warning, title: String(localized: "Recording stopped early"), detail: detail)
    }

    private static func readingTime(of texts: [String?]) -> Double {
        let characters = texts.compactMap(\.self).reduce(0) { $0 + $1.count }

        return min(10, 2 + Double(characters) / 15)
    }
}
