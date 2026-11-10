import Testing
import WaftCore
@testable import WaftFeatures

struct DictationOutcomeTests {
    private nonisolated static let fallback = RewriteFallback.timeout.message(for: .cloud(.claude))

    @Test(arguments: [
        (DictationOutcome.noSpeech, HUDMessage.Kind.information, "Didn't catch that", String?.none),
        (.failed("The model crashed."), .warning, "Transcription failed", "The model crashed."),
        (.partFailed, .warning, "Part of the dictation is missing", "Choose Retry Last Dictation in the Waft menu."),
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
        (TextDelivery.Outcome.pasted, RewriteFallback?.none, HUDMessage.Kind.pasted, String?.none),
        (.pasted, .timeout, .pasted, fallback),
        (.copied, nil, .copied, nil),
        (.copied, .timeout, .copied, fallback),
        (.keptOutOfPasswordField, nil, .copied, "Not pasted into a password field"),
        (.keptOutOfPasswordField, .timeout, .copied, "Not pasted into a password field"),
    ])
    func `shows the delivered text with its detail`(
        delivery: TextDelivery.Outcome,
        reason: RewriteFallback?,
        kind: HUDMessage.Kind,
        detail: String?,
    ) {
        let outcome = DictationOutcome.delivered(delivery, ProcessedText(text: "Hi.", mode: .light, fallback: reason))

        #expect(outcome.message(for: .cloud(.claude)) == HUDMessage(kind: kind, title: "Hi.", detail: detail))
    }
}
