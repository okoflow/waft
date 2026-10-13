import Testing
import WaftCore
@testable import WaftFeatures

struct DictationJobTests {
    @Test
    func `uses the target app's own mode with that mode's instructions`() {
        var settings = Settings(languages: .preferred(by: []))
        settings.appModes.set(.formal, for: "com.example.mail")
        settings.instructions.set("Write like a lawyer.", for: .formal)
        let job = DictationJob(
            samples: [],
            recording: ActiveRecording(id: RecordingID.none.next, purpose: .dictation, key: .function),
            target: .app("com.example.mail"),
            settings: settings,
            vocabulary: .empty,
            allowsAI: true,
        )

        #expect(job.mode == .formal)
        #expect(job.setup.instructions == "Write like a lawyer.")
    }
}
