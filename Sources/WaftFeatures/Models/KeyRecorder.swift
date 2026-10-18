import AppKit
import Observation
import WaftCore

@Observable
final class KeyRecorder {
    struct Rejection: Equatable {
        let purpose: RecordingPurpose
        let isTaken: Bool
    }

    private static let escapeKeyCode: UInt16 = 53

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

        if isKeyDown, event.keyCode == Self.escapeKeyCode {
            stop()

            return
        }

        guard let key = PushToTalkKey(keyCode: Int64(event.keyCode)) else {
            if isKeyDown {
                reject(for: purpose, isTaken: false)
            }

            return
        }

        let isPress = isKeyDown || key.isHeld(in: UInt64(event.modifierFlags.rawValue))
        guard isPress else { return }
        guard key != takenKey else {
            reject(for: purpose, isTaken: true)

            return
        }

        record?(key)
        stop()
    }

    private func reject(for purpose: RecordingPurpose, isTaken: Bool) {
        rejection = Rejection(purpose: purpose, isTaken: isTaken)
        rejections[purpose, default: 0] += 1
    }
}
