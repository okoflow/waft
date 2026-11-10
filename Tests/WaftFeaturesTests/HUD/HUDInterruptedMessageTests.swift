import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct HUDInterruptedMessageTests {
    private static let warning = HUDMessage(kind: .warning, title: "Recording stopped early")
    private static let information = HUDMessage(kind: .information, title: "Didn't catch that")

    @Test(arguments: [HUDMessage.Kind.copied, .warning])
    func `shows a warning or a copied text again after the recording that interrupted it`(kind: HUDMessage.Kind) {
        let hud = model()
        let message = HUDMessage(kind: kind, title: "Hello world")

        hud.show(message)
        hud.showListening(badge: "Light", isHandsFree: false) { 0 }

        #expect(hud.content == .listening(badge: "Light", isHandsFree: false))

        hud.hideListening()

        #expect(hud.content == .message(message))
    }

    @Test(arguments: [HUDMessage.Kind.pasted, .information])
    func `lets a new recording replace a pasted text or a note for good`(kind: HUDMessage.Kind) {
        let hud = model()
        let message = HUDMessage(kind: kind, title: "Hello world")

        hud.show(message)
        hud.showListening(badge: "Light", isHandsFree: false) { 0 }
        hud.hideListening()

        #expect(hud.content == nil)
    }

    @Test
    func `shows the interrupted message before the ones that arrived while listening`() {
        let hud = model()

        hud.show(Self.warning)
        hud.showListening(badge: "Light", isHandsFree: false) { 0 }
        hud.show(Self.information)
        hud.hideListening()

        #expect(hud.content == .message(Self.warning))
    }

    @Test
    func `queues the same message once when it arrives twice in a row`() async {
        let hud = model(expiring: [Self.warning])

        hud.showListening(badge: "Light", isHandsFree: false) { 0 }
        hud.show(Self.warning)
        hud.show(Self.warning)
        hud.hideListening()

        #expect(hud.content == .message(Self.warning))
        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == nil })
    }

    private func model(expiring: [HUDMessage] = []) -> HUDController {
        .offscreen { expiring.contains($0) ? .zero : .seconds(60) }
    }
}
