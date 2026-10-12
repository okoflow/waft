import AppKit
import os
import WaftCore

@MainActor
package final class SystemAppLifecycle: AppLifecycle {
    private static let relaunchScript = "while /bin/kill -0 \"$1\" 2>/dev/null; do /bin/sleep 0.2; done; /usr/bin/open \"$0\""

    package init() {}

    package func relaunch() {
        let waiter = Process()
        waiter.executableURL = URL(filePath: "/bin/sh")
        waiter.arguments = ["-c", Self.relaunchScript, Bundle.main.bundlePath, String(ProcessInfo.processInfo.processIdentifier)]

        do {
            try waiter.run()
        } catch {
            let cause = error as NSError
            Logger.system.error("Couldn't relaunch: \(cause.domain, privacy: .public) \(cause.code, privacy: .public)")

            return
        }

        quit()
    }

    package func quit() {
        NSApplication.shared.terminate(nil)
    }
}
