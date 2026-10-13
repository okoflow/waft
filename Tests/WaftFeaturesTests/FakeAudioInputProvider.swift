import WaftCore

nonisolated struct FakeAudioInputProvider: AudioInputProvider {
    func inputDevices() -> [AudioInputDevice] {
        []
    }
}
