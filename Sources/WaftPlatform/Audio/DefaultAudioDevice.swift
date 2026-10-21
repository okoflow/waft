import CoreAudio

enum DefaultAudioDevice {
    case input
    case output

    var deviceID: AudioDeviceID? {
        var address = AudioObjectPropertyAddress(selector, scope: kAudioObjectPropertyScopeGlobal)
        var deviceID = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        guard status == noErr, deviceID != kAudioObjectUnknown else { return nil }

        return deviceID
    }

    private var selector: AudioObjectPropertySelector {
        switch self {
        case .input:
            kAudioHardwarePropertyDefaultInputDevice

        case .output:
            kAudioHardwarePropertyDefaultOutputDevice
        }
    }
}
