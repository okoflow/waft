package import WaftCore
import AudioToolbox
import CoreAudio

@MainActor
package final class CoreAudioOutputVolume: OutputVolume {
    private struct Lowered {
        let deviceID: AudioDeviceID
        let original: Float32
        let applied: Float32
    }

    private static let tolerance: Float32 = 0.02

    private var lowered: Lowered?

    package init() {}

    private static func defaultOutputDeviceID() -> AudioDeviceID? {
        var address = address(kAudioHardwarePropertyDefaultOutputDevice, scope: kAudioObjectPropertyScopeGlobal)
        var deviceID = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        guard status == noErr, deviceID != kAudioObjectUnknown else { return nil }

        return deviceID
    }

    private static func volume(of deviceID: AudioDeviceID) -> Float32? {
        var address = volumeAddress()
        var volume: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &volume) == noErr else { return nil }

        return volume
    }

    @discardableResult
    private static func setVolume(_ volume: Float32, of deviceID: AudioDeviceID) -> Bool {
        var address = volumeAddress()
        var isSettable: DarwinBoolean = false
        guard AudioObjectIsPropertySettable(deviceID, &address, &isSettable) == noErr, isSettable.boolValue else {
            return false
        }

        var value = min(max(volume, 0), 1)
        let size = UInt32(MemoryLayout<Float32>.size)

        return AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &value) == noErr
    }

    private static func volumeAddress() -> AudioObjectPropertyAddress {
        address(kAudioHardwareServiceDeviceProperty_VirtualMainVolume, scope: kAudioDevicePropertyScopeOutput)
    }

    private static func address(
        _ selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope,
    ) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }

    package func lower(to fraction: Float) {
        guard lowered == nil,
              let deviceID = Self.defaultOutputDeviceID(),
              let original = Self.volume(of: deviceID),
              original > 0
        else { return }

        let applied = original * fraction
        guard Self.setVolume(applied, of: deviceID) else { return }

        lowered = Lowered(deviceID: deviceID, original: original, applied: applied)
    }

    package func restore() {
        guard let lowered else { return }

        self.lowered = nil

        guard let current = Self.volume(of: lowered.deviceID), abs(current - lowered.applied) <= Self.tolerance else {
            return
        }

        Self.setVolume(lowered.original, of: lowered.deviceID)
    }
}
