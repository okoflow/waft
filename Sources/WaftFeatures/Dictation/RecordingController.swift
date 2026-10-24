import Foundation
import Observation
import os
import WaftCore

@Observable
final class RecordingController {
    @ObservationIgnored var onPoll: ((PushToTalk.Event, TimeInterval) -> Void)?
    @ObservationIgnored var onFinish: ((ActiveRecording, FocusTarget, [Float]) -> Void)?

    private(set) var recording: ActiveRecording?

    @ObservationIgnored private var watchdog = ReleaseWatchdog()
    @ObservationIgnored private var lastRecordingID = RecordingID.none

    private let recorder: any AudioRecorder
    private let focusTracker: any FocusTracker
    private let keyboardState: any KeyboardState
    private let sounds: any FeedbackSoundPlayer
    private let otherSounds: OtherSoundsLowering
    private let settings: SettingsModel
    private let hud: HUDController
    private let hudDelay: Duration
    private let watchdogInterval: TimeInterval

    var isRecording: Bool {
        guard let recording else { return false }

        return recording.isLive
    }

    init(
        recorder: any AudioRecorder,
        focusTracker: any FocusTracker,
        keyboardState: any KeyboardState,
        sounds: any FeedbackSoundPlayer,
        otherSounds: OtherSoundsLowering,
        settings: SettingsModel,
        hud: HUDController,
        hudDelay: Duration = .milliseconds(300),
        watchdogInterval: TimeInterval = 0.25,
    ) {
        self.recorder = recorder
        self.focusTracker = focusTracker
        self.keyboardState = keyboardState
        self.sounds = sounds
        self.otherSounds = otherSounds
        self.settings = settings
        self.hud = hud
        self.hudDelay = hudDelay
        self.watchdogInterval = watchdogInterval
    }

    func start() {
        Task { [weak self, events = recorder.events] in
            for await event in events {
                self?.handle(event)
            }
        }
    }

    func begin(_ trigger: RecordingTrigger) {
        var started = makeRecording(for: trigger)
        started.hudTask = scheduleListeningHUD(for: started.id)
        recording = started

        let id = started.id
        let deviceID = settings.settings.microphoneID

        Task { await recorder.start(id, deviceID: deviceID) }
        Task { [weak self] in self?.captureTarget(for: id) }
    }

    func refuse(_ trigger: RecordingTrigger, because reason: String) {
        var refused = makeRecording(for: trigger)
        refused.isRejected = true
        recording = refused

        hud.show(HUDMessage(kind: .information, title: reason))
    }

    func lockHandsFree() {
        recording?.isHandsFree = true

        hud.lockHandsFree()
    }

    func finish(releasedAt time: TimeInterval) {
        guard let ended = end() else { return }

        hud.hideListening(handingOverTo: DictationQueue.transcribingLabel)

        if settings.settings.playsSounds {
            sounds.play(.recordingFinished)
        }

        Task { await deliver(ended, releasedAt: time) }
    }

    func discard(because reason: PushToTalk.DiscardReason) {
        guard let ended = end() else { return }

        hud.hideListening()
        Logger.dictation.info("Discarded the recording: \(reason.rawValue, privacy: .public)")

        stopRecorder(ended.id)
    }

    func resetWatchdog(on keyEvent: KeyEvent) {
        guard let recording, recording.key.isPressed(by: keyEvent) else { return }

        watchdog.reset()
    }

    private func makeRecording(for trigger: RecordingTrigger) -> ActiveRecording {
        lastRecordingID = lastRecordingID.next
        watchdog.reset()

        var made = ActiveRecording(id: lastRecordingID, purpose: trigger.purpose, key: trigger.key)
        made.watchdogTimer = .scheduledInCommonModes(every: watchdogInterval, repeats: true) { [weak self] in
            self?.pollKey()
        }

        return made
    }

    private func end() -> ActiveRecording? {
        guard let ended = recording else { return nil }

        recording = nil
        otherSounds.restore()

        ended.hudTask?.cancel()
        ended.watchdogTimer?.invalidate()

        guard ended.isLive else {
            hud.hideListening()

            return nil
        }

        return ended
    }

    private func handle(_ event: RecordingEvent) {
        switch event {
        case let .started(id, deviceName) where recording?.isLive(withID: id) == true:
            Logger.dictation.info("Recording from \(deviceName)")

            if settings.settings.playsSounds {
                sounds.play(.recordingStarted)
            }

            if settings.settings.lowersOtherSounds {
                otherSounds.lower { [weak self] in self?.recording?.isLive(withID: id) == true }
            }

        case let .failed(id, failure) where recording?.isLive(withID: id) == true:
            fail(with: failure)

        case .started, .failed:
            break
        }
    }

    private func fail(with failure: RecordingFailure) {
        guard var failed = recording else { return }

        failed.hasFailed = true
        recording = failed
        otherSounds.restore()

        hud.hideListening()
        hud.show(.recordingFailed(failure.message))

        stopRecorder(failed.id)
    }

    private func stopRecorder(_ id: RecordingID) {
        Task { _ = await recorder.stop(id, releasedAt: nil) }
    }

    private func scheduleListeningHUD(for id: RecordingID) -> Task<Void, Never> {
        Task { [weak self, hudDelay] in
            guard await Task.slept(for: hudDelay) else { return }

            self?.showListeningHUD(for: id)
        }
    }

    private func showListeningHUD(for id: RecordingID) {
        guard let recording, recording.isLive(withID: id) else { return }

        let recorder = recorder

        hud.showListening(badge: badge(for: recording), isHandsFree: recording.isHandsFree) { recorder.inputLevel }
    }

    private func badge(for recording: ActiveRecording) -> String {
        guard recording.purpose == .dictation else { return String(localized: "Edit") }

        return settings.settings.title(of: settings.settings.mode(for: recording.target?.bundleIdentifier))
    }

    private func captureTarget(for id: RecordingID) {
        guard let started = recording, started.id == id else { return }

        let target = focusTracker.currentFocus()
        recording?.target = target

        guard started.purpose == .edit else { return }
        guard let selection = target.element?.selectedText else {
            reject(started, because: String(localized: "Select the text to edit, then hold the key and say what to change."))

            return
        }

        recording?.selection = selection
    }

    private func reject(_ rejected: ActiveRecording, because reason: String) {
        rejected.hudTask?.cancel()
        recording?.isRejected = true

        hud.hideListening()
        hud.show(HUDMessage(kind: .information, title: reason))

        stopRecorder(rejected.id)
    }

    private func deliver(_ ended: ActiveRecording, releasedAt time: TimeInterval) async {
        let samples = await recorder.stop(ended.id, releasedAt: time)
        guard !samples.isEmpty else {
            await reportMissingAudio(for: ended)

            return
        }

        onFinish?(ended, focus(of: ended), samples)
    }

    private func reportMissingAudio(for recording: ActiveRecording) async {
        guard let failure = await recorder.failure(for: recording.id) else {
            hud.show(.recordingFailed(String(localized: "No audio was captured.")))

            return
        }

        hud.show(.recordingFailed(failure.message))
    }

    private func focus(of recording: ActiveRecording) -> FocusTarget {
        guard let target = recording.target else { return focusTracker.currentFocus() }

        return target
    }

    private func pollKey() {
        guard let recording else { return }

        let now = Uptime.now

        guard !recording.isHandsFree else {
            onPoll?(.tick, now)

            return
        }

        switch watchdog.poll(isHeld: keyboardState.isHeld(recording.key), at: now) {
        case .holding:
            onPoll?(.tick, now)

        case let .released(since):
            Logger.dictation.notice("The key-up never arrived; ending the recording")

            onPoll?(.keyUp, since)
        }
    }
}
