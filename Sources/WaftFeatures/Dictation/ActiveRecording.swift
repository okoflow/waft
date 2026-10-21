import Foundation
import WaftCore

struct ActiveRecording {
    let id: RecordingID
    let purpose: RecordingPurpose
    let key: PushToTalkKey
    var target: FocusTarget?
    var selection: String?
    var hasFailed = false
    var isRejected = false
    var isHandsFree = false
    var hudTask: Task<Void, Never>?
    var watchdogTimer: Timer?

    var isLive: Bool {
        guard !isRejected, !hasFailed else { return false }

        return true
    }

    var isStuckHandsFree: Bool {
        guard isHandsFree else { return false }

        return !isLive
    }

    func isLive(withID id: RecordingID) -> Bool {
        guard self.id == id else { return false }

        return isLive
    }
}
