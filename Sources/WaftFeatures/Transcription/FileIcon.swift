import AppKit
import SwiftUI

struct FileIcon: View {
    let url: URL

    var body: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
            .resizable()
            .frame(width: Metrics.fileIconSize, height: Metrics.fileIconSize)
            .accessibilityHidden(true)
    }
}
