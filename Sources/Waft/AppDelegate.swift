import AppKit
import WaftFeatures

final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel(dependencies: .live())

    func applicationDidFinishLaunching(_: Notification) {
        model.start()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        Task {
            await model.prepareToQuit()

            sender.reply(toApplicationShouldTerminate: true)
        }

        return .terminateLater
    }

    func application(_: NSApplication, open urls: [URL]) {
        for url in urls {
            model.open(url)
        }
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        model.windows.showSettings()

        return false
    }
}
