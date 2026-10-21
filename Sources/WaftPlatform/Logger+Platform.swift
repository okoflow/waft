import Foundation
import os
import WaftCore

extension Logger {
    static let audio = Logger(subsystem: AppIdentity.bundleIdentifier, category: "audio")
    static let insertion = Logger(subsystem: AppIdentity.bundleIdentifier, category: "insertion")
    static let keyboard = Logger(subsystem: AppIdentity.bundleIdentifier, category: "keyboard")
    static let network = Logger(subsystem: AppIdentity.bundleIdentifier, category: "network")
    static let storage = Logger(subsystem: AppIdentity.bundleIdentifier, category: "storage")
    static let system = Logger(subsystem: AppIdentity.bundleIdentifier, category: "system")

    func error(_ message: String, cause: any Error) {
        let failure = cause as NSError

        error("\(message, privacy: .public): \(failure.domain, privacy: .public) \(failure.code, privacy: .public)")
    }
}
