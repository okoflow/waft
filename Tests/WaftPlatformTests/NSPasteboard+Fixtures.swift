import AppKit

extension NSPasteboard {
    static func withTemporary(_ body: (NSPasteboard) throws -> Void) rethrows {
        let pasteboard = NSPasteboard(name: Name("com.okoflow.waft.tests.\(UUID().uuidString)"))
        defer { pasteboard.releaseGlobally() }

        try body(pasteboard)
    }
}
