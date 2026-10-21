import Foundation
import os
import WaftCore

final class DictationController {
    private var triggers = RecordingTriggers()

    private let keyEventMonitor: any KeyEventMonitor
    private let recordings: RecordingController
    private let settings: SettingsModel
    private let permissions: PermissionMonitor
    private let speechModelController: SpeechModelController
    private let vocabulary: VocabularyModel
    private let keyRecorder: KeyRecorder
    private let shortcutRecorder: ShortcutRecorder
    private let pro: ProModel
    private let queue: DictationQueue

    var isRecording: Bool {
        recordings.isRecording
    }

    init(
        keyEventMonitor: any KeyEventMonitor,
        recordings: RecordingController,
        settings: SettingsModel,
        permissions: PermissionMonitor,
        speechModelController: SpeechModelController,
        vocabulary: VocabularyModel,
        keyRecorder: KeyRecorder,
        shortcutRecorder: ShortcutRecorder,
        pro: ProModel,
        queue: DictationQueue,
    ) {
        self.keyEventMonitor = keyEventMonitor
        self.recordings = recordings
        self.settings = settings
        self.permissions = permissions
        self.speechModelController = speechModelController
        self.vocabulary = vocabulary
        self.keyRecorder = keyRecorder
        self.shortcutRecorder = shortcutRecorder
        self.pro = pro
        self.queue = queue

        recordings.onPoll = { [weak self] event, time in
            self?.tick(event, at: time)
        }

        recordings.onFinish = { [weak self] recording, target, samples in
            self?.submit(samples, from: recording, at: target)
        }
    }

    func start() {
        recordings.start()

        Task { [weak self, events = keyEventMonitor.events] in
            for await event in events {
                self?.handle(event)
            }
        }
    }

    func prepareToQuit() {
        recordings.discard(because: .interrupted)
    }

    private func handle(_ keyEvent: KeyEvent) {
        guard !keyRecorder.isRecording, !shortcutRecorder.isRecording else { return }

        recordings.resetWatchdog(on: keyEvent)

        for trigger in triggers.handle(keyEvent, settings: settings.settings) {
            perform(trigger, at: keyEvent.timestamp)
        }
    }

    private func tick(_ event: PushToTalk.Event, at time: TimeInterval) {
        guard let recording = recordings.recording,
              let action = triggers.handle(event, for: recording.purpose, at: time, settings: settings.settings)
        else { return }

        perform(RecordingTrigger(purpose: recording.purpose, key: recording.key, action: action), at: time)
    }

    private func perform(_ trigger: RecordingTrigger, at time: TimeInterval) {
        switch trigger.action {
        case .startRecording:
            guard recordings.recording == nil else { return }

            startRecording(for: trigger)

        case .lockHandsFree:
            guard owns(trigger), recordings.isRecording else {
                abandonHandsFree(for: trigger)

                return
            }

            recordings.lockHandsFree()

        case .finishRecording:
            guard owns(trigger) else { return }

            recordings.finish(releasedAt: time)

        case let .discardRecording(reason):
            guard owns(trigger) else { return }

            recordings.discard(because: reason)
        }
    }

    private func owns(_ trigger: RecordingTrigger) -> Bool {
        recordings.recording?.purpose == trigger.purpose
    }

    private func abandonHandsFree(for trigger: RecordingTrigger) {
        triggers.reset(trigger.purpose)

        guard owns(trigger) else { return }

        recordings.discard(because: .interrupted)
    }

    private func startRecording(for trigger: RecordingTrigger) {
        if let problem = reasonNotToRecord(for: trigger.purpose) {
            recordings.refuse(trigger, because: problem)
        } else {
            recordings.begin(trigger)
        }
    }

    private func reasonNotToRecord(for purpose: RecordingPurpose) -> String? {
        if purpose == .edit, !pro.isUnlocked {
            return String(localized: "Editing by voice is part of Waft+.")
        }

        if let message = speechModelController.state.notReadyMessage {
            return message
        }

        if permissions.status(of: .microphone) == .denied {
            return String(localized: "Waft can't use the microphone. Allow it in Settings › General.")
        }

        return nil
    }

    private func submit(_ samples: [Float], from recording: ActiveRecording, at target: FocusTarget) {
        let current = settings.settings

        if current.appModes.mode(for: target.bundleIdentifier) != nil {
            Logger.dictation.info("Using the app's own mode for \(target.appDescription, privacy: .public)")
        }

        queue.submit(DictationJob(
            samples: samples,
            recording: recording,
            target: target,
            settings: current,
            vocabulary: vocabulary.reloadFromDisk(),
            allowsAI: pro.isUnlocked,
        ))
    }
}
