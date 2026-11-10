import AppKit
import Testing
import WaftCore
@testable import WaftFeatures

struct RecorderDeactivationTests {
    private let settings = SettingsModel.inMemory()

    @Test
    func `stops recording a key when Waft stops being the active app`() async {
        let recorder = KeyRecorder()
        recorder.start(.dictation, excluding: { _ in false }, { _ in })

        NotificationCenter.default.post(name: NSApplication.didResignActiveNotification, object: nil)

        #expect(await Poll.until(timeout: .seconds(5)) { !recorder.isRecording })
    }

    @Test
    func `stops recording a shortcut and resumes the shortcuts when Waft stops being the active app`() async {
        let shortcuts = GlobalShortcutController.fake(settings: settings)
        let recorder = ShortcutRecorder(settings: settings, shortcuts: shortcuts)
        recorder.start(.translator)

        NotificationCenter.default.post(name: NSApplication.didResignActiveNotification, object: nil)

        #expect(await Poll.until(timeout: .seconds(5)) { !recorder.isRecording })
    }
}
