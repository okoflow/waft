package import WaftCore
import CoreAudio

package struct CoreAudioInputs: AudioInputProvider {
    package init() {}

    static func deviceID(for uniqueID: String) -> AudioDeviceID? {
        inputDeviceIDs().first { string(kAudioDevicePropertyDeviceUID, of: $0) == uniqueID }
    }

    static func name(of deviceID: AudioDeviceID) -> String? {
        string(kAudioObjectPropertyName, of: deviceID)
    }

    static func defaultInputName() -> String {
        guard let deviceID = DefaultAudioDevice.input.deviceID, let name = name(of: deviceID) else { return "the default input" }

        return name
    }

    private static func inputDeviceIDs() -> [AudioDeviceID] {
        var address = AudioObjectPropertyAddress(kAudioHardwarePropertyDevices, scope: kAudioObjectPropertyScopeGlobal)
        let system = AudioObjectID(kAudioObjectSystemObject)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return [] }

        var deviceIDs = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &deviceIDs) == noErr else { return [] }

        return deviceIDs.filter(hasInputStreams)
    }

    private static func hasInputStreams(_ deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(kAudioDevicePropertyStreams, scope: kAudioObjectPropertyScopeInput)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size) == noErr else { return false }

        return size > 0
    }

    private static func string(_ selector: AudioObjectPropertySelector, of objectID: AudioObjectID) -> String? {
        var address = AudioObjectPropertyAddress(selector, scope: kAudioObjectPropertyScopeGlobal)
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(objectID, &address, 0, nil, &size, &value) == noErr else { return nil }

        return value?.takeRetainedValue() as String?
    }

    package func inputDevices() -> [AudioInputDevice] {
        Self.inputDeviceIDs().compactMap { deviceID in
            guard let uniqueID = Self.string(kAudioDevicePropertyDeviceUID, of: deviceID),
                  let name = Self.name(of: deviceID) else { return nil }

            return AudioInputDevice(id: uniqueID, name: name)
        }
    }
}
