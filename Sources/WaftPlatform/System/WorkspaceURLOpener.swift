package import Foundation
import AppKit
import WaftCore

@MainActor
package final class WorkspaceURLOpener: URLOpener {
    package init() {}

    package func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    package func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
