import CoreGraphics
import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct HUDControllerTests {
    private static let first = HUDMessage(kind: .information, title: "First")
    private static let second = HUDMessage(kind: .warning, title: "Second")
    private static let third = HUDMessage(kind: .information, title: "Third")
    private static let pasted = HUDMessage(kind: .pasted, title: "Hi.")

    private let window = FakeHUDWindow()
    private let clipboard = FakeClipboard()

    @Test
    func `shows queued messages one at a time in order`() async {
        let hud = model(expiring: [Self.first])

        hud.show(Self.first)
        hud.show(Self.second)
        hud.show(Self.third)

        #expect(hud.content == .message(Self.first))
        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .message(Self.second) })
    }

    @Test
    func `holds messages back while listening and shows them after listening ends`() {
        let hud = model()

        hud.showListening(badge: "Light", isHandsFree: false) { 0 }
        hud.show(Self.first)

        #expect(hud.content == .listening(badge: "Light", isHandsFree: false))

        hud.hideListening()

        #expect(hud.content == .message(Self.first))
    }

    @Test
    func `hands the listening island over to a working label`() {
        let hud = model()

        hud.showListening(badge: "Light", isHandsFree: false) { 0 }
        hud.hideListening(handingOverTo: "Transcribing…")

        #expect(hud.content == .working("Transcribing…"))
    }

    @Test
    func `returns to the working label after a message expires`() async {
        let hud = model(expiring: [Self.first])

        hud.setWorking("Transcribing…")
        hud.show(Self.first)

        #expect(hud.content == .message(Self.first))
        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .working("Transcribing…") })
    }

    @Test
    func `hides the window once the working label clears`() async {
        let hud = model()

        hud.setWorking("Transcribing…")

        #expect(window.isShown)

        hud.setWorking(nil)

        #expect(hud.content == nil)
        #expect(await Poll.until(timeout: .seconds(5)) { !window.isShown })
    }

    @Test
    func `locks only a listening island hands-free, keeping its badge`() {
        let hud = model()

        hud.setWorking("Transcribing…")
        hud.lockHandsFree()

        #expect(hud.content == .working("Transcribing…"))

        hud.showListening(badge: "Clean", isHandsFree: false) { 0 }
        hud.lockHandsFree()

        #expect(hud.content == .listening(badge: "Clean", isHandsFree: true))
    }

    @Test
    func `ignores hiding the listening island when it is not shown`() {
        let hud = model()

        hud.show(Self.first)
        hud.hideListening(handingOverTo: "Transcribing…")

        #expect(hud.content == .message(Self.first))
    }

    @Test
    func `copies the text of a delivered message when it is clicked`() {
        let hud = model()

        hud.show(HUDMessage(kind: .pasted, title: "Hi."))

        #expect(hud.canCopyMessage)

        hud.copyMessage()

        #expect(clipboard.copied == ["Hi."])
        #expect(hud.hasCopied)
    }

    @Test
    func `closes a copied message after a pause and resets it for the next one`() async {
        let hud = model()

        hud.show(HUDMessage(kind: .pasted, title: "Hi."))
        hud.copyMessage()

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == nil })

        hud.show(Self.first)

        #expect(!hud.hasCopied)
    }

    @Test(arguments: [HUDMessage.Kind.copied, .information, .warning])
    func `shows a message with nothing to copy in full and ignores a click on it`(kind: HUDMessage.Kind) {
        let hud = model()

        hud.show(HUDMessage(kind: kind, title: "Hi."))

        #expect(!hud.showsCompactMessage)

        hud.copyMessage()

        #expect(!hud.canCopyMessage)
        #expect(clipboard.copied.isEmpty)
        #expect(!hud.hasCopied)
    }

    @Test
    func `marks when the working card appears and when its step changes`() {
        let hud = model()
        let start = Date.now

        hud.setWorking("Transcribing…")

        #expect(hud.workingSince >= start)
        #expect(hud.stepChangedAt == .distantPast)

        hud.setWorking("Transcribing…")

        #expect(hud.stepChangedAt == .distantPast)

        hud.setWorking("Cleaning up…")

        #expect(hud.stepChangedAt >= hud.workingSince)
    }

    @Test
    func `shows a delivered message compactly until the pointer moves over it`() {
        let hud = model()

        hud.show(Self.pasted)

        #expect(hud.showsCompactMessage)

        point(hud, isOver: true)

        #expect(!hud.showsCompactMessage)

        point(hud, isOver: false)

        #expect(hud.showsCompactMessage)
    }

    @Test
    func `ignores a pointer that rests where the message appears`() {
        let hud = model()

        hud.show(Self.pasted)
        hud.pointerMoved(to: .zero, isOver: true)
        hud.pointerMoved(to: .zero, isOver: true)

        #expect(hud.showsCompactMessage)
    }

    @Test
    func `keeps a delivered message open while the pointer is over it`() async {
        let hud = model(expiring: [Self.pasted])

        hud.show(Self.pasted)
        point(hud, isOver: true)

        #expect(await !(Poll.until(timeout: .milliseconds(300)) { hud.content == nil }))
    }

    @Test
    func `closes a delivered message after a pause once the pointer leaves it`() async {
        let hud = model()

        hud.show(Self.pasted)
        point(hud, isOver: true)
        point(hud, isOver: false)

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == nil })
    }

    @Test
    func `shows the next message compactly after one closes under the pointer`() async {
        let next = HUDMessage(kind: .pasted, title: "Bye.")
        let hud = model()

        hud.show(Self.pasted)
        hud.show(next)
        point(hud, isOver: true)
        hud.copyMessage()

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .message(next) })
        #expect(hud.showsCompactMessage)
    }

    private func point(_ hud: HUDController, isOver: Bool) {
        hud.pointerMoved(to: .zero, isOver: false)
        hud.pointerMoved(to: CGPoint(x: 1, y: 1), isOver: isOver)
    }

    private func model(expiring: [HUDMessage] = []) -> HUDController {
        HUDController(
            messageDuration: { expiring.contains($0) ? .zero : .seconds(60) },
            orderOutPause: .zero,
            copiedPause: .zero,
            copy: { [clipboard] in clipboard.copy($0) },
            makeWindow: { [window] _ in window },
        )
    }
}
