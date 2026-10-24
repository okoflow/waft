import Testing
import WaftCore
@testable import WaftFeatures

struct DictationOutcomeTests {
    private nonisolated static let fallback = RewriteFallback.timeout.message(for: .cloud(.claude))

    @Test(arguments: [
        (
            DictationOutcome.blockedInPasswordField,
            HUDMessage.Kind.warning,
            "Not pasted into a password field",
            String?.some("Choose Copy Last Dictation in the Waft menu."),
        ),
        (.noSpeech, .information, "Didn't catch that", nil),
        (.failed("The model crashed."), .warning, "Transcription failed", "The model crashed."),
        (.editFailed("You're offline"), .warning, "Couldn't edit the text", "You're offline"),
    ])
    func `maps each failure to its HUD message`(
        outcome: DictationOutcome,
        kind: HUDMessage.Kind,
        title: String,
        detail: String?,
    ) {
        #expect(outcome.message(for: .cloud(.claude)) == HUDMessage(kind: kind, title: title, detail: detail))
    }

    @Test(arguments: [
        (DictationOutcome.pasted(ProcessedText(text: "Hi.", mode: .clean)), HUDMessage.Kind.pasted, String?.none),
        (.pasted(ProcessedText(text: "Hi.", mode: .light, fallback: .timeout)), .pasted, fallback),
        (.copied(ProcessedText(text: "Hi.", mode: .clean)), .copied, nil),
        (.copied(ProcessedText(text: "Hi.", mode: .light, fallback: .timeout)), .copied, fallback),
    ])
    func `shows the delivered text with its detail`(outcome: DictationOutcome, kind: HUDMessage.Kind, detail: String?) {
        #expect(outcome.message(for: .cloud(.claude)) == HUDMessage(kind: kind, title: "Hi.", detail: detail))
    }
}
