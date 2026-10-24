import SwiftUI
import WaftFeatures

@main
struct WaftApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarScene(model: appDelegate.model)
    }
}
