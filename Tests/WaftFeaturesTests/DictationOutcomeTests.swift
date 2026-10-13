import Testing
import WaftCore
@testable import WaftFeatures

struct DictationOutcomeTests {
    private nonisolated static let fallback = RewriteFallback.timeout.message(for: .cloud(.claude))

    @Test(arguments: [
        (DictationOutcome.pasted(ProcessedText(text: "Hi.", mode: .clean)), HUDMessage.Kind.pasted, "Hi.", String?.none),
        (.pasted(ProcessedText(text: "Hi.", mode: .light, fallback: .timeout)), .pasted, "Hi.", fallback),
        (.copied(ProcessedText(text: "Hi.", mode: .clean)), .copied, "Hi.", "Copied: press ⌘V to paste"),
        (
            .copied(ProcessedText(text: "Hi.", mode: .light, fallback: .timeout)),
            .copied,
            "Hi.",
            "Copied: press ⌘V to paste\n\(fallback)",
        ),
        (.blockedInPasswordField, .warning, "Not pasted into a password field", "Choose Copy Last Dictation in the Waft menu."),
        (.noSpeech, .information, "Didn't catch that", nil),
        (.failed("The model crashed."), .warning, "Transcription failed", "The model crashed."),
        (.editFailed("You're offline"), .warning, "Couldn't edit the text", "You're offline"),
    ])
    func `maps each outcome to its HUD message`(
        outcome: DictationOutcome,
        kind: HUDMessage.Kind,
        title: String,
        detail: String?,
    ) {
        #expect(outcome.message(for: .cloud(.claude)) == HUDMessage(kind: kind, title: title, detail: detail))
    }
}
