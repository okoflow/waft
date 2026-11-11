import Testing
import WaftCore
@testable import WaftFeatures

struct DictationJobTests {
    @Test(arguments: [
        (Mode.formal, "Write like a lawyer."),
        (.custom(CustomMode.emailReply.id), "<instructions>\nReply as a short email.\n</instructions>"),
    ])
    func `uses the target app's own mode with that mode's instructions`(mode: Mode, instructions: String) {
        var settings = Settings(languages: .preferred(by: []))
        settings.customModes = [.emailReply]
        settings.instructions.set("Write like a lawyer.", for: .formal)
        settings.appModes.set(mode, for: "com.example.mail")

        let job = DictationJob(
            samples: [],
            recording: ActiveRecording(id: .first, purpose: .dictation, key: .function),
            target: .app("com.example.mail"),
            settings: settings,
            vocabulary: .empty,
            allowsAI: true,
        )

        #expect(job.mode == mode)
        #expect(job.setup.instructions.contains(instructions))
    }

    @Test(arguments: [(SecureFieldState.secure, true), (.notSecure, false)])
    func `knows from its target whether a password field had focus when the recording began`(
        state: SecureFieldState,
        isForPasswordField: Bool,
    ) {
        let target = FocusTarget.app("com.example.notes", element: FakeFocusedElement(selectedText: nil, secureFieldState: state))

        #expect(DictationJob.recorded(target: target).isForPasswordField == isForPasswordField)
    }
}
