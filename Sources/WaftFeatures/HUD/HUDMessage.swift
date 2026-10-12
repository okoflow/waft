import Foundation

struct HUDMessage: Equatable, Sendable {
    enum Kind: Sendable {
        case pasted
        case copied
        case info
        case warning
    }

    let kind: Kind
    let title: String
    let detail: String?

    var duration: Duration {
        let characters = [title, detail].compactMap(\.self).reduce(0) { $0 + $1.count }
        let readingTime = min(10, 2 + Double(characters) / 15)
        let seconds = kind == .pasted ? min(readingTime, 4) : readingTime

        return .milliseconds(Int(seconds * 1000))
    }

    init(kind: Kind, title: String, detail: String? = nil) {
        self.kind = kind
        self.title = title
        self.detail = detail
    }

    static func recordingFailed(_ detail: String) -> HUDMessage {
        HUDMessage(kind: .warning, title: String(localized: "Recording failed"), detail: detail)
    }
}
