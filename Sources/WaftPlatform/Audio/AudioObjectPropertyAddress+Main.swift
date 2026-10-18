import CoreAudio

extension AudioObjectPropertyAddress {
    init(_ selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope) {
        self.init(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }
}
