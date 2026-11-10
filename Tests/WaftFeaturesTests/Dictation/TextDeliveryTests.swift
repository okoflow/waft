import Testing
import WaftCore
@testable import WaftFeatures

struct TextDeliveryTests {
    private let clipboard = FakeClipboard()

    @Test
    func `pastes the text into the target and leaves the clipboard alone`() async {
        let inserter = FakeTextInserter()
        let delivery = TextDelivery(inserter: inserter, clipboard: clipboard)

        let outcome = await delivery.deliver("Hello.", into: .notes, releasing: .function)

        #expect(outcome == .pasted)
        #expect(inserter.insertions.map(\.text) == ["Hello."])
        #expect(inserter.insertions.map(\.app) == ["com.example.notes"])
        #expect(clipboard.copied.isEmpty)
    }

    @Test(arguments: [InsertionSkipReason.noAccessibility, .focusChanged, .keyHeld, .notRead])
    func `copies the text when the inserter skips the paste`(reason: InsertionSkipReason) async {
        let delivery = TextDelivery(inserter: FakeTextInserter(.skipped(reason)), clipboard: clipboard)

        let outcome = await delivery.deliver("Hello.", into: .notes, releasing: .function)

        #expect(outcome == .copied)
        #expect(clipboard.copied == ["Hello."])
    }

    @Test
    func `copies the text and says that it stayed out of a password field`() async {
        let delivery = TextDelivery(inserter: FakeTextInserter(.skipped(.secureField)), clipboard: clipboard)

        let outcome = await delivery.deliver("Hello.", into: .notes, releasing: .function)

        #expect(outcome == .keptOutOfPasswordField)
        #expect(clipboard.copied == ["Hello."])
    }

    @Test
    func `copies the text without asking the inserter`() {
        let inserter = FakeTextInserter()
        let delivery = TextDelivery(inserter: inserter, clipboard: clipboard)

        #expect(delivery.copy("Hello.") == .copied)
        #expect(clipboard.copied == ["Hello."])
        #expect(inserter.insertions.isEmpty)
    }
}
