import AppKit
import Observation
import WaftCore

@Observable
final class KeyRecorder {
    enum Rejection: Equatable {
        case typesText
        case taken
    }

    private(set) var purpose: RecordingPurpose?
    private(set) var rejection: Rejection?
    private(set) var rejections: [RecordingPurpose: Int] = [:]

    @ObservationIgnored private var monitor: Any?
    @ObservationIgnored private var takenKey: PushToTalkKey?
    @ObservationIgnored private var record: ((PushToTalkKey) -> Void)?

    var isRecording: Bool {
        purpose != nil
    }

    func start(_ purpose: RecordingPurpose, excluding takenKey: PushToTalkKey?, _ record: @escaping (PushToTalkKey) -> Void) {
        stop()

        self.purpose = purpose
        self.takenKey = takenKey
        self.record = record
        rejection = nil
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] event in
            self?.handle(event)

            return nil
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }

        monitor = nil
        record = nil
        purpose = nil
    }

    func isRecording(_ purpose: RecordingPurpose) -> Bool {
        self.purpose == purpose
    }

    func handle(_ event: NSEvent) {
        guard let purpose else { return }

        let isKeyDown = event.type == .keyDown

        if isKeyDown, event.isEscape {
            stop()

            return
        }

        guard let key = PushToTalkKey(keyCode: Int64(event.keyCode)) else {
            if isKeyDown {
                reject(.typesText, for: purpose)
            }

            return
        }
        guard isPress(of: key, in: event) else { return }
        guard key != takenKey else {
            reject(.taken, for: purpose)

            return
        }

        record?(key)
        stop()
    }

    private func isPress(of key: PushToTalkKey, in event: NSEvent) -> Bool {
        guard event.type != .keyDown else { return true }

        return key.isHeld(in: UInt64(event.modifierFlags.rawValue))
    }

    private func reject(_ rejection: Rejection, for purpose: RecordingPurpose) {
        self.rejection = rejection
        rejections[purpose, default: 0] += 1
    }
}
