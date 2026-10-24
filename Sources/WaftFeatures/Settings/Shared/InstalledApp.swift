import AppKit
import UniformTypeIdentifiers

enum InstalledApp {
    static func name(of bundleIdentifier: String) -> String {
        guard let url = location(of: bundleIdentifier) else { return bundleIdentifier }

        return FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
    }

    static func icon(of bundleIdentifier: String) -> NSImage {
        guard let url = location(of: bundleIdentifier) else { return NSWorkspace.shared.icon(for: .application) }

        return NSWorkspace.shared.icon(forFile: url.path)
    }

    private static func location(of bundleIdentifier: String) -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    }
}
