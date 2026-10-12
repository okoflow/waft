package import Foundation

package enum AppIdentity {
    package static let bundleIdentifier = "com.okoflow.waft"

    private static let name = "Waft"

    package static var supportDirectory: URL {
        URL.applicationSupportDirectory.appending(path: name, directoryHint: .isDirectory)
    }
}
