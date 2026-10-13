package struct RecordingTrigger: Sendable {
    package let purpose: RecordingPurpose
    package let key: PushToTalkKey
    package let action: PushToTalk.Action

    package init(purpose: RecordingPurpose, key: PushToTalkKey, action: PushToTalk.Action) {
        self.purpose = purpose
        self.key = key
        self.action = action
    }
}
