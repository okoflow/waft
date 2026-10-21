import Foundation

struct HUDMessage: Equatable, Sendable {
    enum Kind: Sendable {
        case pasted
        case copied
        case information
        case warning
    }

    private static let pasteShortcut = "⌘V"

    let kind: Kind
    let title: String
    let detail: String?

    var isCopyable: Bool {
        kind == .pasted
    }

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

    static func copied(_ text: String, note: String? = nil) -> HUDMessage {
        let hint = String(localized: "Copied: press \(pasteShortcut) to paste")

        return HUDMessage(kind: .copied, title: text, detail: [hint, note].compactMap(\.self).joined(separator: "\n"))
    }

    static func recordingFailed(_ detail: String) -> HUDMessage {
        HUDMessage(kind: .warning, title: String(localized: "Recording failed"), detail: detail)
    }
}
