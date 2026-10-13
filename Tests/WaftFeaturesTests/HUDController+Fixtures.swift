@testable import WaftFeatures

extension HUDController {
    static func offscreen(messageDuration: @escaping (HUDMessage) -> Duration = \.duration) -> HUDController {
        HUDController(messageDuration: messageDuration, orderOutPause: .zero) { _ in FakeHUDWindow() }
    }
}
