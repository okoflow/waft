import Testing
import WaftCore
@testable import WaftFeatures

struct HUDControllerTests {
    private static let first = HUDMessage(kind: .info, title: "First")
    private static let second = HUDMessage(kind: .warning, title: "Second")
    private static let third = HUDMessage(kind: .info, title: "Third")

    private let window = FakeHUDWindow()

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
        hud.showListening(badge: nil, isHandsFree: false) { 0 }
        hud.show(Self.first)

        #expect(hud.content == .listening(badge: nil, isHandsFree: false))

        hud.hideListening()

        #expect(hud.content == .message(Self.first))
    }

    @Test
    func `hands the listening pill over to a working label`() {
        let hud = model()
        hud.showListening(badge: nil, isHandsFree: false) { 0 }
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
    func `locks only a listening pill hands-free, keeping its badge`() {
        let hud = model()
        hud.setWorking("Transcribing…")
        hud.lockHandsFree()

        #expect(hud.content == .working("Transcribing…"))

        hud.showListening(badge: "Clean", isHandsFree: false) { 0 }
        hud.lockHandsFree()

        #expect(hud.content == .listening(badge: "Clean", isHandsFree: true))
    }

    @Test
    func `ignores hiding the listening pill when it is not shown`() {
        let hud = model()
        hud.show(Self.first)
        hud.hideListening(handingOverTo: "Transcribing…")

        #expect(hud.content == .message(Self.first))
    }

    private func model(expiring: [HUDMessage] = []) -> HUDController {
        HUDController(
            messageDuration: { expiring.contains($0) ? .zero : .seconds(60) },
            orderOutPause: .zero,
            makeWindow: { [window] _ in window },
        )
    }
}
