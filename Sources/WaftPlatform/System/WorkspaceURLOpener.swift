package import Foundation
import AppKit
import os
import WaftCore

@MainActor
package final class WorkspaceURLOpener: URLOpener {
    package init() {}

    package func open(_ url: URL) {
        guard !NSWorkspace.shared.open(url) else { return }

        Logger.system.error("Couldn't open \(url.isFileURL ? "a file" : "a link", privacy: .public)")
    }

    package func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
