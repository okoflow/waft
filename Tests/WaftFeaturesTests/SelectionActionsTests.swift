import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct SelectionActionsTests {
    private let settings = SettingsModel.inMemory()
    private let clipboard = FakeClipboard()
    private let hud = HUDController.offscreen()

    @Test
    func `translates the selection and pastes the translation over it`() async throws {
        let rewriter = FakeTextRewriter(.success("Hello."))
        let inserter = FakeTextInserter()
        let actions = actions(rewriter, selecting: "Привет", detects: .russian, inserter: inserter)
        actions.run(.translate)

        #expect(await Poll.until(timeout: .seconds(5)) { !inserter.insertions.isEmpty })

        let request = try #require(rewriter.requests.first)

        #expect(request.text == "Привет")
        #expect(request.textTask == .translate(from: nil, into: .english))
        #expect(inserter.insertions.map(\.text) == ["Hello."])
        #expect(hud.content == .message(HUDMessage(kind: .pasted, title: "Hello.")))
    }

    @Test
    func `translates a selection in the target language two-way`() async throws {
        settings.settings.translator.translation = Translation(target: .english, twoWayLanguage: .ukrainian)
        let rewriter = FakeTextRewriter(.success("Привіт."))
        let inserter = FakeTextInserter()
        let actions = actions(rewriter, selecting: "Hello", detects: .english, inserter: inserter)
        actions.run(.translate)

        #expect(await Poll.until(timeout: .seconds(5)) { !inserter.insertions.isEmpty })

        let request = try #require(rewriter.requests.first)

        #expect(request.textTask == .translate(from: nil, into: .ukrainian))
    }

    @Test(arguments: [false, true])
    func `fixes the selection with clearer wording when it is on`(rephrases: Bool) async throws {
        settings.settings.translator.rephrases = rephrases
        let rewriter = FakeTextRewriter(.success("We meet on Friday."))
        let inserter = FakeTextInserter()
        let actions = actions(rewriter, selecting: "we meat on friday", detects: .english, inserter: inserter)
        actions.run(.fix)

        #expect(await Poll.until(timeout: .seconds(5)) { !inserter.insertions.isEmpty })

        let request = try #require(rewriter.requests.first)

        #expect(request.textTask == .fix)
        #expect(request.rephrases == rephrases)
        #expect(inserter.insertions.map(\.text) == ["We meet on Friday."])
    }

    @Test(arguments: [InsertionSkipReason.noAccessibility, .focusChanged, .keyHeld, .notRead])
    func `copies the translation when the inserter skips the paste`(reason: InsertionSkipReason) async {
        let actions = actions(
            FakeTextRewriter(.success("Hello.")),
            selecting: "Привет",
            detects: .russian,
            inserter: FakeTextInserter(.skipped(reason)),
        )
        actions.run(.translate)

        #expect(await Poll.until(timeout: .seconds(5)) { clipboard.copied == ["Hello."] })
        #expect(hud.content == .message(HUDMessage(kind: .copied, title: "Hello.", detail: "Copied: press ⌘V to paste")))
    }

    @Test
    func `keeps the translation out of a password field and the clipboard`() async {
        let actions = actions(
            FakeTextRewriter(.success("Hello.")),
            selecting: "Привет",
            detects: .russian,
            inserter: FakeTextInserter(.skipped(.secureField)),
        )
        actions.run(.translate)

        #expect(await Poll.until(timeout: .seconds(5)) {
            hud.content == .message(HUDMessage(kind: .warning, title: "Not pasted into a password field"))
        })
        #expect(clipboard.copied.isEmpty)
    }

    @Test(arguments: [String?.none, " \n"])
    func `asks to select text first`(selection: String?) {
        let rewriter = FakeTextRewriter(.success("Hello."))
        let actions = actions(rewriter, selecting: selection)
        actions.run(.translate)

        #expect(hud.content == .message(HUDMessage(
            kind: .information,
            title: "Select the text first, then press the shortcut.",
        )))
        #expect(rewriter.requests.isEmpty)
    }

    @Test
    func `leaves the selection alone and says why when the model fails`() async {
        let inserter = FakeTextInserter()
        let actions = actions(FakeTextRewriter(.failure(.offline)), selecting: "Привет", detects: .russian, inserter: inserter)
        actions.run(.translate)

        #expect(await Poll.until(timeout: .seconds(5)) {
            hud.content == .message(HUDMessage(kind: .warning, title: "Couldn't translate the text", detail: "You're offline"))
        })
        #expect(inserter.insertions.isEmpty)
    }

    @Test(.enabled(if: !ProAccess.isFreeDuringBeta))
    func `needs Waft+`() {
        let rewriter = FakeTextRewriter(.success("Hello."))
        let actions = actions(rewriter, selecting: "Привет", pro: .unlicensed(trialStarted: .distantPast))
        actions.run(.translate)

        #expect(hud.content == .message(HUDMessage(kind: .information, title: "Translating and fixing text is part of Waft+.")))
        #expect(rewriter.requests.isEmpty)
    }

    private func actions(
        _ rewriter: FakeTextRewriter,
        selecting selection: String?,
        detects language: Language? = nil,
        inserter: FakeTextInserter = FakeTextInserter(),
        pro: ProModel = .unlicensed(),
    ) -> SelectionActions {
        let focus = FocusTarget.app("com.example.notes", element: FakeFocusedElement(selectedText: selection))

        return SelectionActions(
            rewriters: .all(rewriter),
            detector: FakeLanguageDetector(language: language),
            focusTracker: FakeFocusTracker(focus),
            keyboardState: FakeKeyboardState(holdsKeys: false),
            inserter: inserter,
            clipboard: clipboard,
            settings: settings,
            pro: pro,
            hud: hud,
        )
    }
}
